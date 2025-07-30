# Definition for singly-linked list.
class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

from typing import Optional
class Solution:
    def addTwoNumbers(self, l1: Optional[ListNode], l2: Optional[ListNode]) -> Optional[ListNode]:
        dummy = ListNode()      # Dummy head to simplify logic
        current = dummy
        carry = 0

        while l1 or l2 or carry:
            val1 = l1.val if l1 else 0  # value from l1 or 0
            val2 = l2.val if l2 else 0  # value from l2 or 0

            total = val1 + val2 + carry
            carry = total // 10         # update carry
            current.next = ListNode(total % 10)  # add digit node
            current = current.next      # move to next node

            if l1: l1 = l1.next
            if l2: l2 = l2.next

        return dummy.next
