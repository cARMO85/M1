import sys
print(sys.executable)

import sqlalchemy
import pymysql
import pandas as pd
import requests
from datetime import datetime
import pytz
import os

print("Script started.")

# Define your MySQL database connection parameters
user = 'root'
password = 'kildimo123'
host = '127.0.0.1'
port = 3306
schema = 'q10'

# Create the connection string
connection_string = f'mysql+pymysql://{user}:{password}@{host}:{port}/{schema}'

# Function to fetch and process data
def fetch_and_store_data():
    junctions_of_interest = ['02:J2', '06:J6A', '10:J10', '15:J14', '21:J19', '23:J21', '28:J24', '33:J28', '38:J32', '40:J34', '46:J39', '50:J43|44']

    # Fetch data from the API
    url = "https://www.trafficengland.com/api/network/getJunctionSections?roadName=M1"
    response = requests.get(url)
    data_json = response.json()

    data = []
    tz = pytz.timezone('Europe/London')
    now = datetime.now(tz)
    current_time = now.strftime('%H:%M:%S')
    current_date = now.strftime('%Y-%m-%d')
    day_of_week = now.strftime('%A')

    for junction in junctions_of_interest:
        try:
            junction_data = data_json[junction]
            junction_name = junction_data['junctionName']
            direction1 = junction_data['primaryDownstreamJunctionSection']['links'][0]['direction']
            speed_limit1 = junction_data['primaryDownstreamJunctionSection']['links'][0]['speedLimit']
            current_speed1 = round(junction_data['primaryDownstreamJunctionSection']['avgSpeed'], 2)
            direction2 = junction_data['secondaryUpstreamJunctionSection']['links'][0]['direction']
            speed_limit2 = junction_data['secondaryUpstreamJunctionSection']['links'][0]['speedLimit']
            current_speed2 = round(junction_data['secondaryUpstreamJunctionSection']['avgSpeed'], 2)

            data.append({
                'junction_name': junction_name,
                'primary_direction': direction1,
                'primary_speed_limit': speed_limit1,
                'primary_avg_speed': current_speed1,
                'secondary_direction': direction2,
                'secondary_speed_limit': speed_limit2,
                'secondary_avg_speed': current_speed2,
                'record_time': current_time,
                'record_date': current_date,
                'day_of_week': day_of_week
            })
        except KeyError:
            print(f"Data for junction {junction} is missing.")

    df = pd.DataFrame(data)
    engine = sqlalchemy.create_engine(connection_string)
    df.to_sql('junction_data', con=engine, if_exists='append', index=False)

    print("Data inserted successfully!")

fetch_and_store_data()

print("Script ended.")


# Function to export MySQL table to CSV
def export_to_csv():
    engine = sqlalchemy.create_engine(connection_string)
    
    # Read the table data into a pandas DataFrame
    query = "SELECT * FROM junction_data"
    df = pd.read_sql(query, con=engine)
    
    # Define the file path for the CSV export
    file_path = "junction_data_export.csv"
    
    # Export the DataFrame to a CSV file
    df.to_csv(file_path, index=False)
    
    print(f"Data exported successfully to {file_path}!")


# Fetch data and store it into the MySQL database
fetch_and_store_data()

# Export the MySQL table to a CSV file
export_to_csv()

print("Script ended.")