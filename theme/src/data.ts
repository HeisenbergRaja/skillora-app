import type { Skill } from './types';

export const categories = [
  'Design',
  'Development',
  'Marketing',
  'Languages',
  'Academics',
  'Business',
  'Music',
  'Content Creation',
];

export const demoSkills: Skill[] = [
  {
    id: 'skill-design-1',
    userId: 'provider-1',
    providerName: 'Aarav Sharma',
    title: 'Logo & Poster Design',
    description: 'Clean logos, Instagram posters, and simple brand visuals for students and creators.',
    category: 'Design',
    credits: 20,
    rating: 4.8,
    status: 'active',
  },
  {
    id: 'skill-dev-1',
    userId: 'provider-2',
    providerName: 'Maya Iyer',
    title: 'React Website Help',
    description: 'I can help you build a landing page, fix React bugs, and explain components.',
    category: 'Development',
    credits: 35,
    rating: 4.9,
    status: 'active',
  },
  {
    id: 'skill-academic-1',
    userId: 'provider-3',
    providerName: 'Rohan Mehta',
    title: 'Math Tutoring',
    description: 'Algebra, calculus, and exam practice explained in a simple way.',
    category: 'Academics',
    credits: 15,
    rating: 4.6,
    status: 'active',
  },
  {
    id: 'skill-content-1',
    userId: 'provider-4',
    providerName: 'Sara Khan',
    title: 'Video Editing Basics',
    description: 'Learn cuts, transitions, captions, and reels editing workflow.',
    category: 'Content Creation',
    credits: 25,
    rating: 4.7,
    status: 'active',
  },
];
