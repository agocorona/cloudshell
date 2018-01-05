Global idea is described [here](https://gitter.im/Transient-Transient-Universe-HPlay/Ideas?at=597a2a65f5b3458e308a370e)

Case scenarios [this](https://gitter.im/Transient-Transient-Universe-HPlay/Ideas?at=597a61f42723db8d5e521403) [this](https://gitter.im/Transient-Transient-Universe-HPlay/Ideas?at=59fcef7e4ff065ac18b255c6)
 [this](https://gitter.im/Transient-Transient-Universe-HPlay/cloudshell?at=5a26cbd83ae2aa6b3f8d0a96)

on-going ideas, progress report and discussion: [here](https://gitter.im/Transient-Transient-Universe-HPlay/cloudshell)


> Staring from the Unix shell, these are the shortcomings found about the Unix shell philosophy `a | b | c`  that should be fixed:

- No feedback: no upstream communications: b can not communicate with a. No out-of-flow communications in general 
- No reactivity.  b or c can not generate events. a is the only initiator in the form of a stream. No individual events
- No universal interface. Pipes only. What happens when `a` is a server and `b` is a REST client?. An universal interface should compose any kind of program with any other.
- No types
- No remote communications (solved in Plan 9)
- No universal identification. Elements only make sense within a node. Docker solves it
- No installation: If elements are universally identified, they should be installed locally before invoked. So for a cloud shell, installation should be part of the execution in the same way than initialisation is part of execution of a program. 
- No dependencies. because installation is necessary. Docker express dependencies in a imperative way. for that reason Docker images are monolithic. a cloud shell should embrace the functionalities of a shell and a package installer.
- No recovery from failure: No exceptions: No handling if a program return a failure
- No restart from failure: If the process fail,  the state is lost.
- No resource cleaning: uninstalls, deletion of auxiliary files etc
- Other lacking features necessary for composing complex programs: Monitoring, scalability





