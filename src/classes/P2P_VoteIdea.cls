public with sharing class P2P_VoteIdea {
    
    public P2P_DtoIdea dtoIdea {get;set;}
    
    public void thumbsUp(){
        if(dtoIdea.idea.Id != null) insert( new Vote(ParentId=dtoIdea.idea.Id, Type='Up'));
        dtoIdea.isVoteUp = true;
        dtoIdea.voteTotal += 10; 
    }
    
    public void thumbsDown(){
        if(dtoIdea.idea.Id != null) insert( new Vote(ParentId=dtoIdea.idea.Id, Type='Down'));
        dtoIdea.isVoteDown = true;
        dtoIdea.voteTotal -= 10; 
    }
}