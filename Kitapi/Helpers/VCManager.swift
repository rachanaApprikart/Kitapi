//
//  VCManager.swift
//  VIM
//
//  Created by Suneel Apprikart on 31/05/24.
//

import Foundation
import UIKit

struct VCManager {
    static let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    static let splashStoryBoard = UIStoryboard(name: "Splashscreen", bundle: nil)
    static let kitapiTabStoryBoard = UIStoryboard(name: "KitapiTab", bundle: nil)
    static let childTabStoryBoard = UIStoryboard(name: "ChildTab", bundle: nil)

    
    static func openSplashScreenVC() -> SplashScreenViewController? {
        return splashStoryBoard.instantiateViewController(identifier: SplashScreenViewController.sbIdentifier) as? SplashScreenViewController
    }
    
    static func openOnboardingScreenVC() -> OnboardingViewController? {
        return storyBoard.instantiateViewController(identifier: OnboardingViewController.sbIdentifier) as? OnboardingViewController
    }
    
    static func openLoginVC() -> LoginViewController? {
        return storyBoard.instantiateViewController(identifier: LoginViewController.sbIdentifier) as? LoginViewController
    }
    
    static func openSignUpVC() -> SignUpViewController? {
        return storyBoard.instantiateViewController(identifier: SignUpViewController.sbIdentifier) as? SignUpViewController
    }
    
    static func openVerifyOTPVC() -> VerifyOTPViewController? {
        return storyBoard.instantiateViewController(identifier: VerifyOTPViewController.sbIdentifier) as? VerifyOTPViewController
    }
    
    static func openResetPasswordVC() -> ResetPasswordViewController? {
        return storyBoard.instantiateViewController(identifier: ResetPasswordViewController.sbIdentifier) as? ResetPasswordViewController
    }
    
    static func openNewPasswordVC() -> NewPasswordViewController? {
        return storyBoard.instantiateViewController(identifier: NewPasswordViewController.sbIdentifier) as? NewPasswordViewController
    }
    
    static func openCreateChildProfileVC() -> ChildProfileViewController? {
        let vc = storyBoard.instantiateViewController(identifier: ChildProfileViewController.sbIdentifier) as? ChildProfileViewController
        return vc
    }
    
    static func openDatePickerVC() -> DatePickerViewController? {
        let vc = storyBoard.instantiateViewController(identifier: DatePickerViewController.sbIdentifier) as? DatePickerViewController
        return vc
    }
    
    static func openAvatarPickerVC() -> AvatarPickerViewController? {
        let vc = storyBoard.instantiateViewController(identifier: AvatarPickerViewController.sbIdentifier) as? AvatarPickerViewController
        return vc
    }
    
    
    static func openTabBarVC() -> KitapiTabViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: KitapiTabViewController.sbIdentifier) as? KitapiTabViewController
    }
    
    static func openChoresVC() -> ChoresViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: ChoresViewController.sbIdentifier) as? ChoresViewController
    }
    static func openGoalsVC() -> GoalsViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: GoalsViewController.sbIdentifier) as? GoalsViewController
    }
    
    static func openChildListVC() -> ChildrenListViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: ChildrenListViewController.sbIdentifier) as? ChildrenListViewController
    }
    
    static func openCreateChoresVC() -> CreateChoreViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: CreateChoreViewController.sbIdentifier) as? CreateChoreViewController
    }
    
    static func openRecordVoiceNoteVC() -> RecordVoiceNoteViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: RecordVoiceNoteViewController.sbIdentifier) as? RecordVoiceNoteViewController
    }
    
    static func openTimePickerVC() -> TimePickerViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: TimePickerViewController.sbIdentifier) as? TimePickerViewController
    }
    
    static func openChoreTemplateVC() -> ChoreTemplateViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: ChoreTemplateViewController.sbIdentifier) as? ChoreTemplateViewController
    }
    
    static func openChoreTemplateImageVC() -> SelectTemplateImageViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: SelectTemplateImageViewController.sbIdentifier) as? SelectTemplateImageViewController
    }
    
    static func openCalenderVC() -> CalenderViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: CalenderViewController.sbIdentifier) as? CalenderViewController
    }
    
    static func openChoreDetailsVC() -> ChoreDescriptionViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: ChoreDescriptionViewController.sbIdentifier) as? ChoreDescriptionViewController
    }
    
    static func openMPINVC() -> MPINViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: MPINViewController.sbIdentifier) as? MPINViewController
    }
    
    static func opensetTimerVC() -> SetTimerViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: SetTimerViewController.sbIdentifier) as? SetTimerViewController
    }
    
    static func openCreateGoalsVC() -> CreateGoalViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: CreateGoalViewController.sbIdentifier) as? CreateGoalViewController
    }
    
    static func openGoalTypeVC() -> GoalTypeViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: GoalTypeViewController.sbIdentifier) as? GoalTypeViewController
    }
    
    static func openMilestoneVC() -> MilestoneViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: MilestoneViewController.sbIdentifier) as? MilestoneViewController
    }
    
    static func openAssignChoresVC() -> AssignChoreViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: AssignChoreViewController.sbIdentifier) as? AssignChoreViewController
    }
    
    static func openGoalDetailsVC() -> GoalDetailViewController? {
        return kitapiTabStoryBoard.instantiateViewController(identifier: GoalDetailViewController.sbIdentifier) as? GoalDetailViewController
    }
    
    
    static func openChildTabBarVC() -> ChildTabViewController? {
        return childTabStoryBoard.instantiateViewController(identifier: ChildTabViewController.sbIdentifier) as? ChildTabViewController
    }
    
    static func openReAuthVC() -> ReAuthViewController? {
        return childTabStoryBoard.instantiateViewController(identifier: ReAuthViewController.sbIdentifier) as? ReAuthViewController
    }
    
    static func openPlayGameVC() -> PlayGameViewController? {
        return childTabStoryBoard.instantiateViewController(identifier: PlayGameViewController.sbIdentifier) as? PlayGameViewController
    }
    
    static func openQuitGameVC() -> QuitGameViewController? {
        return childTabStoryBoard.instantiateViewController(identifier: QuitGameViewController.sbIdentifier) as? QuitGameViewController
    }
}
