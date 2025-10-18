#%%
import pandas as pd
import sqlalchemy

import datetime as dtime

from tqdm import tqdm

from datetime import date, datetime
from dateutil.relativedelta import relativedelta

TABLE_NAME = "fs_lifecycle"
DB_ORIGIN = "analytics"
DB_ORIGIN_PATH = f"sqlite:///../../data/{DB_ORIGIN}/database.db"
ANALYTICS_PATH = "sqlite:///../../data/analytics/database.db"

QUERY_NAME = f"../feature_store/{TABLE_NAME}"

DATE_START = '2024-09-30'
DATE_END = '2025-09-30'

def import_query(path):
    with open(path) as open_file:
        query = open_file.read()
    return query

def date_range(date_start, date_stop):
    dates = []
    while date_start <= date_stop:
        dates.append(date_start)
        dt_start = datetime.strptime(date_start, "%Y-%m-%d") + dtime.timedelta(days=1)
        date_start = datetime.strftime(dt_start, "%Y-%m-%d")
    return dates

#%%
query = import_query(f"{QUERY_NAME}.sql")
engine_app = sqlalchemy.create_engine(DB_ORIGIN_PATH)
engine_analytical = sqlalchemy.create_engine(ANALYTICS_PATH)

for date in tqdm(date_range(DATE_START, DATE_END)):
    with engine_analytical.connect() as con:
        try:
            query_delete = f"DELETE FROM {TABLE_NAME} WHERE dtRef = DATE('{date}', '-1 day')"
            con.execute(sqlalchemy.text(query_delete))
            con.commit()
        except Exception as err:
            print(err)

    query_format = query.format(date=date)
    df = pd.read_sql(query_format, engine_app)
    df.to_sql(TABLE_NAME, engine_analytical, index=False, if_exists="append")


#%%
