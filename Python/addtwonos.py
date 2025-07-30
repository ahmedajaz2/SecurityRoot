# Definition for singly-linked list.
class ListNode:
     def __init__(self, val=0, next=None):
         self.val = val
         self.next = next
from typing import Optional
class Solution:
    def addTwoNumbers(self, l1: Optional[ListNode], l2: Optional[ListNode]) -> Optional[ListNode]:
        if not l1:
            return None
        head1=ListNode(l1[0])
        current1=head1
        for val1 in l1[1:]:
            current1.next=ListNode(val1)
            current1=current1.next
        LL1=head1
        if not l2:
            return None
        head2=ListNode(l2[0])
        current2=head2
        for val2 in l2[1:]:
            current2.next=ListNode(val2)
            current2=current2.next
        LL2=head2
        print(LL1)
        print(LL2)
        
