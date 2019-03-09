import _vcmp

callbacks = {}

def callback(func):
    fname = func.__name__
    if not getattr(_vcmp.callbacks, fname):
        callbacks[fname] = []
        def f(*args, **kwargs):
            retval = True
            for fn in callbacks[fname]:
                ret = fn(*args, **kwargs)
                if isinstance(ret, bool):
                    retval = retval and ret
                elif isinstance(ret, str): # on_incoming_connection return str change player name
                    retval = ret
            return retval
        setattr(_vcmp.callbacks, fname, f)
    callbacks[fname].append(func)
    return func
