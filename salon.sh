#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"
echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "\nWelcome to My Salon, how can I help you?\n"

MAIN_MENU() {
  if [[ $1 ]]; then
    echo -e "\n$1"
  fi

  # Show available services
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  
  # If there are no services available
  if [[ -z $SERVICES ]]; then
    echo "Sorry, we don't have any service right now."
  else
    # Display services
    echo -e "$SERVICES" | while read SERVICE_ID BAR NAME; do
      echo "$SERVICE_ID) $NAME"
    done

    # Get customer choice
    read SERVICE_ID_SELECTED

    # Validate the choice
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
      MAIN_MENU "Sorry, that is not a valid number! Please, choose again."
    else
      VALID_SERVICE=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED")
      
      if [[ -z $VALID_SERVICE ]]; then
        MAIN_MENU "I could not find that service. What would you like today?"
      else
        # Get customer phone number
        echo -e "\nWhat's your phone number?"
        read CUSTOMER_PHONE
        
        # Check if the customer is new or existing
        CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
        
        if [[ -z $CUSTOMER_NAME ]]; then
          # New customer
          echo -e "\nI don't have a record for that phone number, what's your name?"
          read CUSTOMER_NAME
          
          # Insert new customer into the database
          CUSTOMER_INFO_INCLUSION=$($PSQL "INSERT INTO customers(phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
        else
          # Existing customer
          CUSTOMER_NAME=$(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g') # Trim whitespace
        fi
        
        # Get the service name
        SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
        
        # Get the appointment time
        echo "What time would you like your $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')?"
        read SERVICE_TIME
        
        # Get customer ID
        CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
        
        # Insert appointment into the database
        APPOINTMENT_INCLUSION=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
        
        # Confirm the appointment
        echo -e "\nI have put you down for a $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g') at $SERVICE_TIME, $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
      fi
    fi
  fi
}

MAIN_MENU
