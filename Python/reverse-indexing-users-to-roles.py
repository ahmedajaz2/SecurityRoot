def group_roles(user_roles):
    role_users={}
    for user,role in user_roles:
        if role not in role_users:
            role_users[role]=[]

        role_users[role].append[user]

    return role_users
