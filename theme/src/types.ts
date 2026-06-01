export type UserProfile = {
  uid: string;
  name: string;
  email: string;
  bio: string;
  credits: number;
  rating: number;
  profileImage?: string;
};

export type Skill = {
  id: string;
  userId: string;
  providerName: string;
  title: string;
  description: string;
  category: string;
  credits: number;
  rating: number;
  status: "active" | "paused";
};

export type SkillRequestStatus =
  | "pending"
  | "accepted"
  | "completed"
  | "cancelled";

export type SkillRequest = {
  id: string;
  skillId: string;
  skillTitle: string;
  requesterId: string;
  requesterName: string;
  providerId: string;
  providerName: string;
  credits: number;
  status: SkillRequestStatus;
};

export type Page =
  | "dashboard"
  | "marketplace"
  | "requests"
  | "add-skill"
  | "wallet"
  | "profile";
