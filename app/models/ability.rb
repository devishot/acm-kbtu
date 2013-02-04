class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    
    can :manage, :all    
=begin
    if user.admin?
        can :manage, :all
    elsif user.student?
        #Submit
        can [:read, :create], Submit
        can [:show_sourcecode, :download_sourcecode], Submit, :participant => { :user_id => user.id }
    elsif user.teacher?
        can :create, Page
        can :manage, Page, :user_id => user.id        
        #Contest
        can :create, Contest
        can :manage, Contest, :user_id => user.id
        #Problem
        can :manage, Problem, :contest => { :user_id => user.id }
    end
=end


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
