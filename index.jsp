<%

    String params = request.getQueryString();

    if(params == null)
        response.sendRedirect("/index.html?offline=1");
    else if(!params.contains("offline=1"))
        response.sendRedirect("/index.html?offline=1&" + request.getQueryString());
    else
        response.sendRedirect("/index.html?" + request.getQueryString());

%>