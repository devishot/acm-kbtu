yesno:
  YES + " or " + NO + " (case insensetive)"

fcmp:
  compare files as sequence of lines

lcmp:
  compare files as sequence of tokens in lines

wcmp:
  compare sequences of tokens  


acmp:
  compare two doubles, maximal absolute error = %.10lf, 1.5E-6

dcmp:
  compare two doubles, maximal absolute or relative error = %.10lf, 1E-6
  

rcmp4:
  compare two sequences of doubles, max absolute or relative error = %.5lf, 1E-4

rcmp6:
  compare two sequences of doubles, max absolute or relative  error = %.7lf, 1E-6

rcmp9:
  compare two sequences of doubles, max absolute or relative error = %.10lf, 1E-9

rncmp:
  compare two sequences of doubles, maximal absolute error = %.10lf, 1.5E-5    
      
      
hcmp:
  compare two signed huge integers
  
icmp:  
  compare two signed int's
  
ncmp:
  compare   ordered sequences of signed int numbers
  
uncmp:
  compare unordered sequences of signed int numbers  
  
  
pointscmp:
  example of scored checker  
  
caseicmp:
  Checker to compare output and answer in the form:
  * Case 1: <number>
  * Case 2: <number>
  * ...
  * Case n: <number>
  
casencmp:
  Checker to compare output and answer in the form:
  * Case 1: <number> <number> <number> ... <number>
  * Case 2: <number> <number> <number> ... <number>
  * ...
  * Case n: <number> <number> <number> ... <number>


