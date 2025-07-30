class Listnode():
    def __init__(self,val=0,next=None):
        self.val=val
        self.next=next
def print_list(head):
    while head:
        print(head.val,end="->")
        head=head.next
    print("None")
from typing import List
def create_list(values=None):
    if not values:
        return None
    head=Listnode(values[0])
    current=head
    for val in values[1:]:
        current.next=Listnode(val)
        current=current.next
    return head

        
