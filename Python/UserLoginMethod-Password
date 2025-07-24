def convertoHash(pswd):
    import hashlib
    return hashlib.sha256(pswd.encode()).hexdigest()

users=dict()


def load_users_from_file(filename):
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or ':' not in line:
                continue  # skip empty or malformed lines
            
            username, hashed_password = line.split(':', 1)
            users[username] = hashed_password

def save_users_to_file(filename):
    with open(filename, 'w') as f:
        for username, hashed_password in users.items():
            f.write(f"{username}:{hashed_password}\n")

def CreateUser(Username):
    UserPassword=input("Create a password : ")
    Password2=input("Verify password : ")
    if UserPassword==Password2:
        users.update({Username:convertoHash(UserPassword)})
        save_users_to_file("users.txt")
        print("User created, proceed to login.")
        UserLogin()
    else:
        print("Password didn't match, please try again")
        CreateUser(Username)
    
    
def UserLogin():
    load_users_from_file("users.txt")
    #print(f"The current set of Users are : {users.keys()}")
    Username=input("Enter your Username : ")
    CheckPassword(Username)

def CheckPassword(Username):
    if Username in users:
        UserPassword=convertoHash(input("Enter your password : "))
        if UserPassword==users[Username]:
            print("Login Successful")
        else:
            print("Wrong password, Try again.")
            CheckPassword(Username)
    else:
        print(f"User {Username} is not registered, please register below : ")
        CreateUser(Username)

UserLogin()
