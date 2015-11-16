%lex
%%

\s+                                 /* skip whitespace */
"@"                                 return '@';
":"                                 return ':';
([a-zA-Z0-9]+"."[a-zA-Z0-9]+)("."[a-zA-Z0-9]+)*      return 'alpha_dot_string';
([a-zA-Z0-9]+"."[a-zA-Z0-9]+)("."[a-zA-Z0-9]+)*      return 'number_dot_string';
[a-zA-Z]+                           return 'string';
[0-9]+                              return 'digit';
[0-9a-zA-Z]+                        return 'alpha';
[0-9a-zA-Z/~.]+                      return 'path_string';


/lex

%start remote_location
%%

remote_location
    : user "@" host ":" path
        {
            $$ = {
                type: "RemoteLocationType",
                user: $1,
                host: $3,
                path: $5
            };
            return $$;
        }
    | user "@" host
        {
            $$ = {
                type: "remote_locationType",
                user: $1,
                host: $3,
                path: {
                    type: "PathType",
                    path: "~"
                }
            };
            return $$;
        }
    ;

user
    : string ":" string
        {
            $$ = {
                type: "UserType",
                user: $1,
                password: $3
            };
        }
    | string
        {
            $$ = {
                type: "UserType",
                user: $1,
                password: null
            };
        }
    ;

host
    : alpha_dot_string
        {
            $$ = {
                type: "HostType",
                host: $1
            };
        }
    | number_dot_string
        {
            $$ = {
                type: "HostType",
                host: $1
            };
        }
    ;

path
    : path_string
        {
            $$ = {
                type: "PathType",
                path: $1
            };
        }
    ;
