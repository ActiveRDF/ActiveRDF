echo "<> <http://www.w3.org/2004/12/ql#select> { ?s ?p ?o . }; <http://www.w3.org/2004/12/ql#where> { ?s ?p ?o . } ." > /tmp/delete.nt
java -jar yars-api-current.jar -d -u http://opteron:8080/test\_node\_factory /tmp/delete.nt 
