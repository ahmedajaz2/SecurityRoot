from datetime, import timedelta

def is_brute_force(logs):
    attempts = {}
    flag_users =()
    for user, status, timestamp in logs:
        if status == "FAILED":
            if user not in attempts:
                attempts[user]=[]
            attempts[user].append(timestamp)
            recent=[]
            for attempt_time in attempts[user]:
                if (timestamp - attempt_time) <= timedelta(minutes=3):
                    recent.append(attempt_time)
            if len(recent)>=5:
                flag_users.add(user)

    return flag_users


                
                    
            
        
