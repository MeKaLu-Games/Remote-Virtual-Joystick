def decode_data(data):
    if data == "null": return "null"

    l = []
    index = 0
    last_index = 0
    while(True):
        b = False
        
        index = data.find(':', last_index)
        if index < 0: 
            b = True
            index = len(data)
        
        a = data[last_index:index]
        
        if a == ':' or a == '': 
            last_index += 1
            continue
        
        l.append(a)
        last_index = index
        if b: break
    return l

#print(decode_data("hello:100:200:300:400"))
