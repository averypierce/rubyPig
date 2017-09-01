# rubyPig
WIP ruby version of pig networking project

-pigs can connect to each other to form a network chain and send data back and forth
-if a pig disconnects from the network chain, remaining pigs attempt to reestablish connection without it
-Each pig can be used to view/filter/edit the messages as they are passed through
eg pig0 could use a filter to encrypt a message, pig1 could be used to view and verify that the message is actually encrypted during transport
,and pig2 could use a filter to decrypt the message. 

