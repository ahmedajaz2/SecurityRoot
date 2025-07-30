def two_sums(array,total):
    number_index={}
    for i, num in enumerate(array):
        other=total-num
        if other in number_index:
            return [number_index[other],i]
        number_index[num]=i
