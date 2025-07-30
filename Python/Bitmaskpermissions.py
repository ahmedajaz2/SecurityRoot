
def check_access(user_perm, perm):
    return (user_perm & perm) !=0

def grant_access(user_perm, perm):
    user_perm |= perm
    print(bin(user_perm))
    return user_perm

def remove_access(user_perm, perm):
    user_perm &= ~perm
    print(bin(user_perm))
    return user_perm

