public with sharing class P2P_DtoIdea {
    
    public Idea idea {get;set;}
    public Integer commentCount {get;set;}
    public Double voteTotal {get;set;}
    public boolean isVoteUp {get;set;}
    public boolean isVoteDown {get;set;}
    public integer index {get;set;}
    
    public P2P_DtoIdea(Idea idea, Integer commentCount, boolean isVoteUp, boolean isVoteDown, integer index){
        this.idea = idea;
        this.commentCount = commentCount;
        this.isVoteUp = isVoteUp;
        this.isVoteDown = isVoteDown;
        this.voteTotal = idea.VoteTotal;
        this.index = index;
    }
}