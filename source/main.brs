sub main(args as Object)
    print "################"
    print "Start of Channel"
    print "################"

    ' Print launch arguments for debugging


    print "Launch args:"

    if args <> invalid
        print "IT's VALID"
        print args

        for each key in args
            print key + ": " + args[key]
        end for
    end if

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    ' Create input object for deep linking
    input = CreateObject("roInput")
    input.SetMessagePort(m.port)

    scene = screen.CreateScene("MainScene")

    ' FIXED: Pass launch arguments to scene
    if args <> invalid
        print "Passing launch args to scene"
        scene.launchArgs = args
    end if

    ' Create URL transfer object
    ut = CreateObject("roURLTransfer")
    ut.SetPort(m.port)
    ut.SetURL("https://roku.cbcfamily.church/rokufeed")
    ut.SetCertificatesFile("common:/certs/ca-bundle.crt")
    ut.InitClientCertificates()

    print "Fetching feed from https://roku.cbcfamily.church/rokufeed"

    if ut.AsyncGetToString() then
        feedReceived = false
        screen.show()

        while true
            msg = wait(100, m.port)
            msgType = type(msg)

            if msgType = "roInputEvent" then
                info = msg.GetInfo()
                print "Received input event: "; info

                if info <> invalid and type(info) = "roAssociativeArray" then
                    print "Input info received:"
                    for each key in info
                        print key + ": " + info[key]
                    end for

                    ' Check if this is a deep link and pass to scene
                    scene.inputData = info
                end if
            else if msgType = "roUrlEvent" and not feedReceived
                code = msg.GetResponseCode()
                print "Response received with code: "; code

                if code = 200
                    feedString = msg.GetString()
                    feed = ParseJson(feedString)

                    if feed <> invalid
                        print "Feed parsed successfully - sending to scene"
                        scene.feed = feed
                        feedReceived = true
                        print "Feed loaded successfully - any pending deep links will now be processed"
                    else
                        print "Error parsing feed JSON"
                    end if
                else
                    print "Error fetching feed. Response code: "; code
                    ' We might want to retry the feed fetch here
                    print "Consider implementing retry logic for feed fetching"
                end if
            else if msgType = "roSGScreenEvent"
                if msg.isScreenClosed()
                    print "Exiting channel"
                    return
                end if
            end if
        end while
    end if
end sub

function getDeepLinkArgs() as Object
    ' This function is intentionally simplified to avoid compatibility issues
    ' For the test script, launch args will be captured by the InputTask component instead

    ' Return empty to avoid any startup errors
    return invalid
end function

function parseQueryParams(queryString as String) as Object
    params = CreateObject("roAssociativeArray")

    ' Remove any leading ? if present
    if Left(queryString, 1) = "?"
        queryString = Right(queryString, Len(queryString) - 1)
    end if

    ' Split by & to get parameter pairs
    pairs = queryString.Split("&")
    for each pair in pairs
        ' Split pair by = to get key and value
        keyValue = pair.Split("=")
        if keyValue.Count() = 2
            params[keyValue[0]] = keyValue[1]
        end if
    end for

    return params
end function