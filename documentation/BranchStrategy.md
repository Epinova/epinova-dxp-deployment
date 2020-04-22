# Branch strategy
At Epinova, we try to use the GitFlow branching strategy in as many projects as possible. If you are not familiar with GitFlow, I suggest that you read the following tutorial [https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow).  
  
In the big picture we want developers to create a “feature” branch from the “developer” branch for each task. When developer is done with the task, hen should do a pull-request so that other developers can review and check that your code is ok. We do this to learn from each other. It also automatically starts a lot of good discussions between developers.   
  
When the “feature” branch is approved and merged, into the “developer” branch. We want Azure DevOps to build and release the “developer” branch to the Episerver DXP Integration environment/site. We look at the Integration environment as internal test website.  
  
After a period, you might decide that it’s time to release something to production. Then a “release candidate” branch should be created from the “developer” branch. When the “release candidate” branch is created, we want Azure DevOps to build and release it to the Preproduction environment so that tests can be made on a more stable codebase. If everything is approved, and working as expected, Preproduction can then be released to the Production environment. We look at the Preproduction environment as the customer acceptance test environment.  
  
The above is of course very simplified description, but I think it is nice to describe what kind of context we try to achieve here.
