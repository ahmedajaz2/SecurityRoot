import datetime
def printDate(Y,M,D):
    date=datetime.datetime(Y,M,D)
    print(date.strftime("%a"))
    print(date.strftime("%b"))
    print(date.strftime("%d"))
    print(date.strftime("%Y"))
    print(date.strftime("%x"))

