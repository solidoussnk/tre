(fn mozilla? ()  (< -1 (navigator.user-agent.index-of "Mozilla")))
(fn webkit? ()   (< -1 (navigator.user-agent.index-of "WebKit")))
(fn opera? ()    (< -1 (navigator.user-agent.index-of "Opera")))
(fn gecko? ()    (< -1 (navigator.user-agent.index-of "Gecko")))
(fn explorer? () (eql "Microsoft Internet Explorer" navigator.app-name))
