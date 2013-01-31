class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    
    if user.admin?
        can :manage, :all
    elsif user.moderator?
        can :manage, [Node, Page]
    elsif user.author?
        can :read, Node
        can [:read, :create], Page
        can [:destroy, :update], Page, :user_id => user.id
    elsif user.student?
        #Contest
        can [:read, :download_statement, :participate, :standings, :messages, :summary], Contest
        #Problem
        can :read, Problem
        #Submit
        can [:read, :create], Submit
        can [:show_sourcecode, :download_sourcecode], Submit, :participant => { :user_id => user.id }
    elsif user.teacher?
        #Contest
        can [:create, :read], Contest
        can :manage, Contest, :user_id => user.id
        #Problem
        can :manage, Problem, :contest => { :user_id => user.id }
    else
        can :read, [Node, Page]
    end

    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
