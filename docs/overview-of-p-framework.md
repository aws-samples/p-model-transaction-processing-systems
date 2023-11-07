# Overview of P Framework

P framework (https://p-org.github.io/P/) is a formal modeling method and language for analysis of distributed systems. 
This is designed and developed by Ankush Desai (https://www.linkedin.com/in/ankush-desai/) as part of his PHD thesis and further refined during his tenure at Amazon Web Services.
It allows you to express the architecture of your distributed systems as collaborating state machines. It has three primary constructs.

* ***State Machine***: It allows you to express each component of your distributed system as a state machine, that responds to a set of events from other state machines. Your distributed system can be described as a set of state machines that can interact with each other by sending each other events.
* ***Specification***: It allows you to describe the essential behavior of your distributed systems as invariants in the form of a specification. You can think of a spec as a third party observer that observes exchange of events between state machines and validates that the distributed systems satisfies the invariants specified.
* ***Tests***: It allows you to create a set of tests to validate that your distributed system satisfies the specification under different test scenarios. 