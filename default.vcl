vcl 4.0;
# Based on: https://github.com/mattiasgeniar/varnish-4.0-configuration-templates/blob/master/default.vcl

import std;
import directors;

backend server1 {
    .host = "${VARNISH_BACKEND_IP}";
    .port = "${VARNISH_BACKEND_PORT}";

    .probe = {
        .request =
            "${VARNISH_BACKEND_PROBE_METHOD} ${VARNISH_BACKEND_PROBE_URL} HTTP/1.1"
            "Host: ${VARNISH_BACKEND_PROBE_HOST}"
            "Connection: close";

        .timeout = 5s; # check the health of each backend every 5 seconds
        .interval = 1s; # timing out after 1 second.
        .window = 8; # If 3 out of the last 5 polls succeeded the backend is considered healthy, otherwise it will be marked as sick
        .threshold = 3;
        .initial = 2; # On startup act as if the previous 2 polls were OK so only 1 more OK within the window is needed for the backend to be considered healthy
    }
}

sub vcl_init {
    new vdir = directors.round_robin();
    vdir.add_backend(server1);
}

sub vcl_recv {

    # Add ping url to test Varnish status.
    if ((req.method  == "GET" || req.method == "HEAD") && req.url ~ "^/varnish_ruok") {
        return (synth(200, "OK"));
    }
   
    set req.http.host = "${VARNISH_BACKEND_PROBE_HOST}" ;

    set req.backend_hint = vdir.backend(); # send all traffic to the vdir director

    if (req.restarts == 0) {
        if (req.http.X-Forwarded-For) { # set or append the client.ip to X-Forwarded-For header
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    # Only deal with "normal" types
    if (req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "PUT" &&
        req.method != "POST" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "PATCH" &&
        req.method != "DELETE") {
      /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }

    # Only cache GET or HEAD requests. This makes sure the POST requests are always passed.
    if (req.method != "GET" && req.method != "HEAD") {
      return (pass);
    }

    if (req.http.Authorization) {
      # Not cacheable by default
      return (pass);
    }

    return (hash);
}
