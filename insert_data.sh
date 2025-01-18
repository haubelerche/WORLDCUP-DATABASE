#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Pre-load all team names into a Bash associative array for quick lookup
declare -A TEAM_IDS

# Load existing teams into the associative array
while read -r TEAM_ID TEAM_NAME
do
  TEAM_IDS["$TEAM_NAME"]=$TEAM_ID
done < <($PSQL "SELECT team_id, name FROM teams")

# Process the CSV and insert data
tail -n +2 games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  # Check if WINNER is already in TEAM_IDS, insert if not
  if [[ -z ${TEAM_IDS["$WINNER"]} ]]
  then
    $PSQL "INSERT INTO teams(name) VALUES('$WINNER')"
    TEAM_IDS["$WINNER"]=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
  fi

  # Check if OPPONENT is already in TEAM_IDS, insert if not
  if [[ -z ${TEAM_IDS["$OPPONENT"]} ]]
  then
    $PSQL "INSERT INTO teams(name) VALUES('$OPPONENT')"
    TEAM_IDS["$OPPONENT"]=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
  fi

  # Insert game data
  WINNER_ID=${TEAM_IDS["$WINNER"]}
  OPPONENT_ID=${TEAM_IDS["$OPPONENT"]}
  $PSQL "INSERT INTO games(winner_id, opponent_id, winner_goals, opponent_goals, year, round) VALUES($WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS, $YEAR, '$ROUND')"
done
