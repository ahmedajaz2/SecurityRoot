import re
def get_failed_logins(logs):
    pattern=re.compile(r"Failed Login for User (\w+)")
    #failed_logins=set()
    #for log in logs.splitlines():
       # if pattern.search(log):
       #     match = pattern.search(log)
       #     failed_logins.add(match.group(1))
            
    #return failed_logins
    return [match.group(1) for log in logs.splitlines() if (match:=pattern.search(log))]
