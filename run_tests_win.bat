@echo off

:: the environment variables

set MONGO_VERSION=3.2
set ORION_VERSION=1.15.1

set INFLUX_VERSION=1.2.2
set RETHINK_VERSION=2.3.5
set CRATE_VERSION=3.0.5

set REDIS_VERSION=3

set QL_IMAGE=quantumleap

:: build the quantumleap image

docker build -t quantumleap .

:: run translator tests

cd src/translators/tests
docker-compose up --quiet-pull -d
timeout 16 /nobreak
docker run -ti --rm --network tests_translatorstests quantumleap pytest translators/tests
docker-compose down
cd ../../..

REM :: run reporter tests

cd src/reporter/tests
docker-compose up --quiet-pull -d
timeout 20 /nobreak
docker run -ti --rm --network tests_reportertests quantumleap pytest reporter/tests
docker-compose down
cd ../../..

REM :: run geocoding tests

cd src/geocoding/tests
docker-compose up --quiet-pull -d
timeout 8 /nobreak
docker run -ti --rm --network tests_geocodingtests quantumleap pytest geocoding/tests
docker-compose down -v
cd ../../..

:: run component integration tests

cd src/tests
docker-compose -f ../../docker/docker-compose-dev.yml up --quiet-pull -d
timeout 60 /nobreak
docker run -ti --rm --network docker_default -e ORION_URL="http://orion:1026" -e QL_URL="http://quantumleap:8668" quantumleap pytest tests/test_integration.py
docker-compose -f ../../docker/docker-compose-dev.yml down -v
cd ../..

:: remove quantumleap image

docker rmi quantumleap
