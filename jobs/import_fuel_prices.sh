#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

CSV_DIR="${CSV_DIR:-${ROOT_DIR}/csvs}"
CSV_PATH="${1:-}"

if [[ -n "$CSV_PATH" && "$CSV_PATH" != /* && -f "${CSV_DIR}/${CSV_PATH}" ]]; then
  CSV_PATH="${CSV_DIR}/${CSV_PATH}"
fi

if [[ -z "$CSV_PATH" ]]; then
  CSV_PATH="$(ls -t "${CSV_DIR}"/UpdatedFuelPrice-*.csv 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "$CSV_PATH" || ! -f "$CSV_PATH" ]]; then
  echo "CSV file not found. Pass a path or a filename in ${CSV_DIR}." >&2
  exit 1
fi

if command -v realpath >/dev/null 2>&1; then
  CSV_PATH="$(realpath "$CSV_PATH")"
fi

DB_URL="${DATABASE_URL:-postgresql://benzene:benzene@localhost:5432/benzene}"

psql "$DB_URL" \
  -v ON_ERROR_STOP=1 <<SQL
BEGIN;

DROP TABLE IF EXISTS stations_next;
DROP TABLE IF EXISTS stations_old;

CREATE TABLE stations_next (LIKE stations INCLUDING ALL);

CREATE TEMP TABLE stations_raw (
  latest_update_timestamp text,
  mft_name text,
  forecourts_node_id text,
  forecourts_trading_name text,
  forecourts_brand_name text,
  forecourts_is_motorway_service_station text,
  forecourts_is_supermarket_service_station text,
  forecourts_public_phone_number text,
  forecourts_temporary_closure text,
  forecourts_permanent_closure text,
  forecourts_permanent_closure_date text,
  location_postcode text,
  location_address_line_1 text,
  location_address_line_2 text,
  location_city text,
  location_county text,
  location_country text,
  location_latitude text,
  location_longitude text,
  fuel_price_e5 text,
  fuel_price_e10 text,
  fuel_price_b7p text,
  fuel_price_b7s text,
  fuel_price_b10 text,
  fuel_price_hvo text,
  monday_open_time text,
  monday_close_time text,
  monday_is_24_hours text,
  tuesday_open_time text,
  tuesday_close_time text,
  tuesday_is_24_hours text,
  wednesday_open_time text,
  wednesday_close_time text,
  wednesday_is_24_hours text,
  thursday_open_time text,
  thursday_close_time text,
  thursday_is_24_hours text,
  friday_open_time text,
  friday_close_time text,
  friday_is_24_hours text,
  saturday_open_time text,
  saturday_close_time text,
  saturday_is_24_hours text,
  sunday_open_time text,
  sunday_close_time text,
  sunday_is_24_hours text,
  bank_holiday_standard_open_time text,
  bank_holiday_standard_close_time text,
  bank_holiday_standard_is_24_hours text,
  amenity_adblue_pumps text,
  amenity_adblue_packaged text,
  amenity_lpg_pumps text,
  amenity_car_wash text,
  amenity_air_pump_or_screenwash text,
  amenity_water_filling text,
  amenity_twenty_four_hour_fuel text,
  amenity_customer_toilets text
) ON COMMIT DROP;

\echo Using CSV ${CSV_PATH}
\copy stations_raw FROM '${CSV_PATH}' WITH (FORMAT csv, HEADER true)

INSERT INTO stations_next (
  node_id,
  latest_update_timestamp,
  mft_name,
  trading_name,
  brand_name,
  is_motorway_service_station,
  is_supermarket_service_station,
  public_phone_number,
  temporary_closure,
  permanent_closure,
  permanent_closure_date,
  location_postcode,
  location_address_line_1,
  location_address_line_2,
  location_city,
  location_county,
  location_country,
  location_latitude,
  location_longitude,
  fuel_price_e5,
  fuel_price_e10,
  fuel_price_b7p,
  fuel_price_b7s,
  fuel_price_b10,
  fuel_price_hvo,
  monday_open_time,
  monday_close_time,
  monday_is_24_hours,
  tuesday_open_time,
  tuesday_close_time,
  tuesday_is_24_hours,
  wednesday_open_time,
  wednesday_close_time,
  wednesday_is_24_hours,
  thursday_open_time,
  thursday_close_time,
  thursday_is_24_hours,
  friday_open_time,
  friday_close_time,
  friday_is_24_hours,
  saturday_open_time,
  saturday_close_time,
  saturday_is_24_hours,
  sunday_open_time,
  sunday_close_time,
  sunday_is_24_hours,
  bank_holiday_standard_open_time,
  bank_holiday_standard_close_time,
  bank_holiday_standard_is_24_hours,
  amenity_adblue_pumps,
  amenity_adblue_packaged,
  amenity_lpg_pumps,
  amenity_car_wash,
  amenity_air_pump_or_screenwash,
  amenity_water_filling,
  amenity_twenty_four_hour_fuel,
  amenity_customer_toilets,
  geom
)
SELECT
  NULLIF(forecourts_node_id, ''),
  CASE
    WHEN latest_update_timestamp <> '' THEN
      to_timestamp(
        split_part(latest_update_timestamp, ' GMT', 1),
        'Dy Mon DD YYYY HH24:MI:SS'
      ) AT TIME ZONE 'UTC'
  END,
  NULLIF(mft_name, ''),
  NULLIF(forecourts_trading_name, ''),
  NULLIF(forecourts_brand_name, ''),
  NULLIF(forecourts_is_motorway_service_station, '')::boolean,
  NULLIF(forecourts_is_supermarket_service_station, '')::boolean,
  NULLIF(forecourts_public_phone_number, ''),
  NULLIF(forecourts_temporary_closure, '')::boolean,
  NULLIF(forecourts_permanent_closure, '')::boolean,
  NULLIF(forecourts_permanent_closure_date, ''),
  NULLIF(location_postcode, ''),
  NULLIF(location_address_line_1, ''),
  NULLIF(location_address_line_2, ''),
  NULLIF(location_city, ''),
  NULLIF(location_county, ''),
  NULLIF(location_country, ''),
  NULLIF(location_latitude, '')::double precision,
  NULLIF(location_longitude, '')::double precision,
  NULLIF(regexp_replace(fuel_price_e5, '[^0-9.]', '', 'g'), '')::numeric(8,4),
  NULLIF(regexp_replace(fuel_price_e10, '[^0-9.]', '', 'g'), '')::numeric(8,4),
  NULLIF(regexp_replace(fuel_price_b7p, '[^0-9.]', '', 'g'), '')::numeric(8,4),
  NULLIF(regexp_replace(fuel_price_b7s, '[^0-9.]', '', 'g'), '')::numeric(8,4),
  NULLIF(regexp_replace(fuel_price_b10, '[^0-9.]', '', 'g'), '')::numeric(8,4),
  NULLIF(regexp_replace(fuel_price_hvo, '[^0-9.]', '', 'g'), '')::numeric(8,4),
  NULLIF(monday_open_time, '')::time,
  NULLIF(monday_close_time, '')::time,
  NULLIF(monday_is_24_hours, '')::boolean,
  NULLIF(tuesday_open_time, '')::time,
  NULLIF(tuesday_close_time, '')::time,
  NULLIF(tuesday_is_24_hours, '')::boolean,
  NULLIF(wednesday_open_time, '')::time,
  NULLIF(wednesday_close_time, '')::time,
  NULLIF(wednesday_is_24_hours, '')::boolean,
  NULLIF(thursday_open_time, '')::time,
  NULLIF(thursday_close_time, '')::time,
  NULLIF(thursday_is_24_hours, '')::boolean,
  NULLIF(friday_open_time, '')::time,
  NULLIF(friday_close_time, '')::time,
  NULLIF(friday_is_24_hours, '')::boolean,
  NULLIF(saturday_open_time, '')::time,
  NULLIF(saturday_close_time, '')::time,
  NULLIF(saturday_is_24_hours, '')::boolean,
  NULLIF(sunday_open_time, '')::time,
  NULLIF(sunday_close_time, '')::time,
  NULLIF(sunday_is_24_hours, '')::boolean,
  NULLIF(bank_holiday_standard_open_time, '')::time,
  NULLIF(bank_holiday_standard_close_time, '')::time,
  NULLIF(bank_holiday_standard_is_24_hours, '')::boolean,
  NULLIF(amenity_adblue_pumps, '')::boolean,
  NULLIF(amenity_adblue_packaged, '')::boolean,
  NULLIF(amenity_lpg_pumps, '')::boolean,
  NULLIF(amenity_car_wash, '')::boolean,
  NULLIF(amenity_air_pump_or_screenwash, '')::boolean,
  NULLIF(amenity_water_filling, '')::boolean,
  NULLIF(amenity_twenty_four_hour_fuel, '')::boolean,
  NULLIF(amenity_customer_toilets, '')::boolean,
  CASE
    WHEN NULLIF(location_latitude, '') IS NOT NULL
     AND NULLIF(location_longitude, '') IS NOT NULL THEN
      ST_SetSRID(
        ST_MakePoint(
          NULLIF(location_longitude, '')::double precision,
          NULLIF(location_latitude, '')::double precision
        ),
        4326
      )::geography
  END
FROM stations_raw;

ANALYZE stations_next;

ALTER TABLE stations RENAME TO stations_old;
ALTER TABLE stations_next RENAME TO stations;
DROP TABLE stations_old;

COMMIT;
SQL

echo "Import complete: ${CSV_PATH}"
