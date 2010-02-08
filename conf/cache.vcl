director usesthis round-robin {
    { .backend = { .host = "127.0.0.1"; .port = "3000"; } }
    { .backend = { .host = "127.0.0.1"; .port = "3001"; } }
    { .backend = { .host = "127.0.0.1"; .port = "3002"; } }
}

sub vcl_fetch {
    set obj.ttl = 1m;
}

sub vcl_recv {
    unset req.http.cookie;
}