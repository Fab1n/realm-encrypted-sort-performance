# What this is all about
Upgrading from `Realm 3.19.0` to `Realm 10.1.4` we noticed a HUGE performance drop for some of our customers.  
This led to a deeper investigation of what the problem was.  
It couldn't have been our code because we just did `pod update Realm RealmSwift` and immediately experienced a huge performance drop all over the place.  

With this project you should be able to see the performance drop in a very particular, singular place. We nailed the problem down to:
- Having an encrypted Realm,
- having an entity with 2 specific fields (`String` (UUID) and `Bool` (all `false`!) in this case - but could be others),
- having a lot of objects with this one entity (`1_000_000` in this case),
- then sorting using `SortDescriptors`, first by the `Bool` property, then by the `String` property
is working A LOT faster on `3.19.0` and pretty slow on `>= 10.1.4`.

We're using Realm/RealmSwift in one of our projects. We have a very complex project with a complex Realm Schema.  
We have around 27 entities, some are lightweight, some have lots of properties and lots of relationships.

A typical database has lots of objects of mainly 2 entities (name them `EntityA` and `EntityB`), `EntityA` is the main entity where performance matters.  
This entity has a relationship to `EntityB` with typically 1 to 5 objects attached to it, but `EntityB` is pretty lightweight in terms of property count and relationships.

This is just for you to know the background a little bit.  

For this performance test here it doesn't really matter.

The thing with our app is that sorted `Results` of `EntityA` are used a lot - the same way we use it in the example project - and thus we notice the performance drop A LOT. Also there are other entities that are sorted alike and everything together made our app really really slow for users with a bit more data in their database.  

I kinda know where the source of the problem is, but I don't know why and especcially why it is such a huge problem. I profiled our app, this test app and many other scenarios.  
The thing that came up the most had to do with `locking`.  
`realm::util::Mutex::lock()` popped up a lot, in the same stacktrace with `realm::util::do_encryption_read_barrier(...)` and `realm::ConstTableView::doSort(...)`.  

I think I read in the `RealmCore` repo or in some commit or merge request that introducing the locking mechanism should lead to around 10% performance loss in most cases (don't remember where I read that exactly).  

In this test project you will notice around `100%` performance loss, depending on your machine, which target your run and other circumstances. But the performance loss over the time for me was always around `100%`, meaning the specific case here is twice as slow with `10.1.4` and `10.5.1` as with `3.19.0`.  

In our app the performance loss is A LOT more dramatic. The same sorting test with our Schema and a Database, having `100_000` objects of the to-be-sorted entity (in the same way as done in the test project here - but with our `EntityA` which is huge and 3 more `SortDescriptors`), led to a 3x performance loss, so it is somehow more significant than in this example project - I don't know why.

I didn't bisect all versions between 3 and 10 to find out where the problem was introduced, you will get that faster than me, I think.

Now let's get down to business and see how you can get real numbers.

# How to test
In the test project you have to `pod install` for every realm version you are testing (there are 3 commits each with a different realm version prepared, but you can change the realm version by hand in the Podfile directly).
The project has 2 targets, one for iOS and one for macOS, but the test results are similar (I didn't test on device for iOS though).

I added signposts via the `OSLog` framework, so you should fire up Instruments with the `Logging` template or just the `os_signpost` instrument.

You now should jump between the commits in order to use Realm `3.19.0`, `10.1.4` or `10.5.1` (the commits are properly named - I did avoid branches for simplicity). Then you should do the following steps:

For iOS:
- Build and run the app
- Press the `write` button to generate a database with `1_000_000` entries
- Now fire up Instruments with the above mentioned tools
- Press the record button
- In the simulator press the `read` button
- Give it a little time and check in Instruments the `os_signpost` tool - the measured times should go up (signposts are logged to the logger)
- The process is done when it is possible to tap the button again (synchronous task)

For macOS (it is a commandline app, but nealy as easy as on iOS):
- Build and run the app
- You will get console output in the Xcode console view asking you to enter a command
- Enter `generate` as text in the console view (yes, you can enter text there in the last empty line) to generate a database with `1_000_000` entries
- Now fire up Instruments with the above mentioned tools
- Important: You are still running the commandline app in Xcode, so you need to attach to it instead of starting it via Instruments. To do that press on the `<your mac name> > target name` button in the top left and select the target `macOS` in the list of running processes (it may not be visible on the top so you need to click on `more` to reveal the process)
- Now you can press the record button
- Switch back to the console view in Xcode and type in `test-sort` (it is possible that this doesn't work - in that case type it again - Xcode console input is picky with the cursor)
- Give it a little time and check in Instruments the `os_signpost` tool - the measured times should go up
- The process is done when the console output gives you the choice again to input something (like `exit` - which stops the app)


Instruments should show the different durations for the different Realm calls as named signposts. You can switch between signpost "List: Intervals" and "Summary: Intervals" in order to checkout which part of the task took how long.
The most interesting signpost is `getting a few elements` (this is where we read 10 random elements out of the sorted list).

The time this signpost recorded matters most.

Now go to the commits where the other realm versions were installed, checkout each version and compare the times.

You'll notice that `3.19.0` is the fastest version.


# Where to go from here
Somewhere down the line Realm algorithms were update und somehow things got worse, speaking about the sorting performance.
I don't know the real reason behind it or if someone else noticed something like that, but I'd be happy to know the reason and if it is possible to fix things there.

I wanted it to be as simple and comprehensible as possible, thus I wrote such a long description and kept the project as simple as possible.

I think this is not the only place where performance got so much worse, but I didn't have the time to look into all problems, so I picked the best problem I could find.

**Please give me feedback and talk to me, I am waiting for your input! If you need some additional help, please don't hesitate to ask for it.**

Thank you very much for your help and work!
