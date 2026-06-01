import { type ReactNode, useEffect, useMemo, useState } from "react";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  onSnapshot,
} from "firebase/firestore";
import {
  BookOpen,
  BriefcaseBusiness,
  ClipboardList,
  Coins,
  Edit3,
  LayoutDashboard,
  LogOut,
  PlusCircle,
  Search,
  Sparkles,
  Star,
  Store,
  Trash2,
  User,
  Wallet,
  X,
} from "lucide-react";
import {
  createUserWithEmailAndPassword,
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
} from "firebase/auth";

import { categories, demoSkills } from "./data";
import { auth, db, firebaseEnabled } from "./lib/firebase";
import type {
  Page,
  Skill,
  SkillRequest,
  SkillRequestStatus,
  UserProfile,
} from "./types";

const demoUser: UserProfile = {
  uid: "demo-user",
  name: "Demo Learner",
  email: "demo@skillora.app",
  bio: "Learning and exchanging skills on Skillora.",
  credits: 100,
  rating: 4.8,
};

function App() {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [skills, setSkills] = useState<Skill[]>(demoSkills);
  const [requests, setRequests] = useState<SkillRequest[]>([]);
  const [page, setPage] = useState<Page>("dashboard");
  const [authMode, setAuthMode] = useState<"login" | "register">("login");
  const [loading, setLoading] = useState(firebaseEnabled);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!firebaseEnabled || !auth || !db) {
      const storedUser = localStorage.getItem("skillora-user");
      const storedSkills = localStorage.getItem("skillora-skills");
      const storedRequests = localStorage.getItem("skillora-requests");
      if (storedUser) setUser(JSON.parse(storedUser) as UserProfile);
      if (storedSkills) setSkills(JSON.parse(storedSkills) as Skill[]);
      if (storedRequests) {
        setRequests(JSON.parse(storedRequests) as SkillRequest[]);
      }
      setLoading(false);
      return;
    }

    let skillsUnsub: (() => void) | null = null;
    let requestsUnsub: (() => void) | null = null;

    return onAuthStateChanged(auth, async (firebaseUser) => {
      setLoading(true);

      // cleanup previous subscriptions if any
      skillsUnsub?.();
      requestsUnsub?.();

      if (!firebaseUser) {
        setUser(null);
        setLoading(false);
        return;
      }

      const fallbackProfile: UserProfile = {
        uid: firebaseUser.uid,
        name: firebaseUser.displayName || "Skillora User",
        email: firebaseUser.email || "",
        bio: "",
        credits: 100,
        rating: 0,
        profileImage: firebaseUser.photoURL || "",
      };

      setUser(fallbackProfile);
      setLoading(false);

      try {
        const userRef = doc(db!, "users", firebaseUser.uid);
        const userDoc = await getDoc(userRef);
        const profile = userDoc.exists()
          ? (userDoc.data() as UserProfile)
          : fallbackProfile;

        if (!userDoc.exists()) {
          await setDoc(userRef, {
            ...profile,
            createdAt: serverTimestamp(),
          });
        }

        setUser(profile);

        // Real-time subscription for skills
        const skillsQuery = query(collection(db!, "skills"), orderBy("createdAt", "desc"));
        skillsUnsub = onSnapshot(
          skillsQuery,
          (snapshot) => {
            console.log('Firestore skills snapshot:', snapshot.docs.length);
            const nextSkills = snapshot.docs.map((item) => ({
              ...(item.data() as Omit<Skill, "id">),
              id: item.id,
            }));
            setSkills(nextSkills.filter((skill) => skill.status === "active"));
          },
          (err) => {
            console.error('Skills subscription error', err);
            setError(firestoreSetupMessage(err));
          },
        );

        // Real-time subscription for requests (filtered client-side)
        const requestsQuery = query(collection(db!, "requests"), orderBy("createdAt", "desc"));
        requestsUnsub = onSnapshot(
          requestsQuery,
          (snapshot) => {
            const nextRequests = snapshot.docs
              .map((item) => ({
                ...(item.data() as Omit<SkillRequest, "id">),
                id: item.id,
              }))
              .filter(
                (request) =>
                  request.requesterId === firebaseUser.uid ||
                  request.providerId === firebaseUser.uid,
              );
            setRequests(nextRequests);
          },
          (err) => setError(firestoreSetupMessage(err)),
        );

        setError("");
      } catch (err) {
        setSkills(demoSkills);
        setError(firestoreSetupMessage(err));
      }
    });
  }, []);

  const mySkills = useMemo(() => {
    if (!user) return [];
    return skills.filter((skill) => skill.userId === user.uid);
  }, [skills, user]);

  async function loadFirebaseSkills() {
    if (!db) return;
    const snapshot = await getDocs(
      query(collection(db, "skills"), orderBy("createdAt", "desc")),
    );
    const nextSkills = snapshot.docs.map((item) => ({
      ...(item.data() as Omit<Skill, "id">),
      id: item.id,
    }));
    setSkills(nextSkills.filter((skill) => skill.status === "active"));
  }

  async function loadFirebaseRequests(userId: string) {
    if (!db) return;
    const snapshot = await getDocs(
      query(collection(db, "requests"), orderBy("createdAt", "desc")),
    );
    const nextRequests = snapshot.docs
      .map((item) => ({
        ...(item.data() as Omit<SkillRequest, "id">),
        id: item.id,
      }))
      .filter(
        (request) =>
          request.requesterId === userId || request.providerId === userId,
      );
    setRequests(nextRequests);
  }

  async function handleLogin(email: string, password: string) {
    setError("");
    setLoading(true);
    try {
      if (firebaseEnabled && auth) {
        const credential = await signInWithEmailAndPassword(
          auth,
          email,
          password,
        );
        setUser({
          uid: credential.user.uid,
          name: credential.user.displayName || "Skillora User",
          email: credential.user.email || email,
          bio: "",
          credits: 100,
          rating: 0,
          profileImage: credential.user.photoURL || "",
        });
      } else {
        const nextUser = { ...demoUser, email };
        setUser(nextUser);
        localStorage.setItem("skillora-user", JSON.stringify(nextUser));
      }
    } catch (err) {
      setError(toMessage(err));
    } finally {
      setLoading(false);
    }
  }

  async function handleRegister(name: string, email: string, password: string) {
    setError("");
    setLoading(true);
    try {
      if (firebaseEnabled && auth && db) {
        const credential = await createUserWithEmailAndPassword(
          auth,
          email,
          password,
        );
        const profile: UserProfile = {
          uid: credential.user.uid,
          name,
          email,
          bio: "",
          credits: 100,
          rating: 0,
        };
        setUser(profile);
        setDoc(doc(db, "users", credential.user.uid), {
          ...profile,
          createdAt: serverTimestamp(),
        }).catch((err) => {
          setError(firestoreSetupMessage(err));
        });
      } else {
        const nextUser: UserProfile = {
          uid: "demo-user",
          name,
          email,
          bio: "",
          credits: 100,
          rating: 0,
        };
        setUser(nextUser);
        localStorage.setItem("skillora-user", JSON.stringify(nextUser));
      }
    } catch (err) {
      setError(toMessage(err));
    } finally {
      setLoading(false);
    }
  }

  async function handleGoogleLogin() {
    setError("");
    setLoading(true);
    try {
      if (firebaseEnabled && auth) {
        const provider = new GoogleAuthProvider();
        const credential = await signInWithPopup(auth, provider);
        setUser({
          uid: credential.user.uid,
          name: credential.user.displayName || "Skillora User",
          email: credential.user.email || "",
          bio: "",
          credits: 100,
          rating: 0,
          profileImage: credential.user.photoURL || "",
        });
      } else {
        setUser(demoUser);
        localStorage.setItem("skillora-user", JSON.stringify(demoUser));
      }
    } catch (err) {
      setError(toMessage(err));
    } finally {
      setLoading(false);
    }
  }

  async function handleLogout() {
    if (firebaseEnabled && auth) await signOut(auth);
    setUser(null);
    setPage("dashboard");
    localStorage.removeItem("skillora-user");
  }

  async function handleAddSkill(
    input: Pick<Skill, "title" | "description" | "category" | "credits">,
  ) {
    if (!user) return;
    setError("");
    const skill: Skill = {
      id: crypto.randomUUID(),
      userId: user.uid,
      providerName: user.name,
      title: input.title,
      description: input.description,
      category: input.category,
      credits: input.credits,
      rating: 0,
      status: "active",
    };

    try {
      if (firebaseEnabled && db) {
        const { id: _id, ...skillData } = skill;
        await addDoc(collection(db, "skills"), {
          ...skillData,
          createdAt: serverTimestamp(),
        });
        await loadFirebaseSkills();
      } else {
        const nextSkills = [skill, ...skills];
        setSkills(nextSkills);
        localStorage.setItem("skillora-skills", JSON.stringify(nextSkills));
      }
      setPage("marketplace");
    } catch (err) {
      setError(toMessage(err));
    }
  }

  async function handleUpdateSkill(
    skillId: string,
    input: Pick<Skill, "title" | "description" | "category" | "credits">,
  ) {
    setError("");
    const currentSkill = skills.find((skill) => skill.id === skillId);
    if (!currentSkill || !user || currentSkill.userId !== user.uid) return;

    const updatedSkill: Skill = {
      ...currentSkill,
      title: input.title,
      description: input.description,
      category: input.category,
      credits: input.credits,
    };

    try {
      if (firebaseEnabled && db) {
        await updateDoc(doc(db, "skills", skillId), {
          title: input.title,
          description: input.description,
          category: input.category,
          credits: input.credits,
          updatedAt: serverTimestamp(),
        });
      }

      const nextSkills = skills.map((skill) =>
        skill.id === skillId ? updatedSkill : skill,
      );
      setSkills(nextSkills);
      if (!firebaseEnabled) {
        localStorage.setItem("skillora-skills", JSON.stringify(nextSkills));
      }
    } catch (err) {
      setError(toMessage(err));
    }
  }

  async function handleRequestSkill(skill: Skill) {
    if (!user) return;
    setError("");

    if (skill.userId === user.uid) {
      setError("You cannot request your own skill.");
      return;
    }

    const existingRequest = requests.find(
      (request) =>
        request.skillId === skill.id &&
        request.requesterId === user.uid &&
        ["pending", "accepted"].includes(request.status),
    );

    if (existingRequest) {
      setError("You already have an active request for this skill.");
      setPage("requests");
      return;
    }

    const request: SkillRequest = {
      id: crypto.randomUUID(),
      skillId: skill.id,
      skillTitle: skill.title,
      requesterId: user.uid,
      requesterName: user.name,
      providerId: skill.userId,
      providerName: skill.providerName,
      credits: skill.credits,
      status: "pending",
    };

    try {
      if (firebaseEnabled && db) {
        const { id: _id, ...requestData } = request;
        const created = await addDoc(collection(db, "requests"), {
          ...requestData,
          createdAt: serverTimestamp(),
        });
        setRequests([{ ...request, id: created.id }, ...requests]);
      } else {
        const nextRequests = [request, ...requests];
        setRequests(nextRequests);
        localStorage.setItem("skillora-requests", JSON.stringify(nextRequests));
      }
      setPage("requests");
    } catch (err) {
      setError(toMessage(err));
    }
  }

  async function handleUpdateRequestStatus(
    requestId: string,
    status: SkillRequestStatus,
  ) {
    setError("");
    const currentRequest = requests.find((request) => request.id === requestId);
    if (!currentRequest || !user) return;

    const isProvider = currentRequest.providerId === user.uid;
    const isRequester = currentRequest.requesterId === user.uid;
    const canUpdate =
      (status === "accepted" && isProvider) ||
      (status === "completed" && isProvider) ||
      (status === "cancelled" && (isProvider || isRequester));

    if (!canUpdate) {
      setError("You are not allowed to update this request.");
      return;
    }

    try {
      if (firebaseEnabled && db) {
        await updateDoc(doc(db, "requests", requestId), {
          status,
          updatedAt: serverTimestamp(),
        });
      }

      const nextRequests = requests.map((request) =>
        request.id === requestId ? { ...request, status } : request,
      );
      setRequests(nextRequests);
      if (!firebaseEnabled) {
        localStorage.setItem("skillora-requests", JSON.stringify(nextRequests));
      }
    } catch (err) {
      setError(toMessage(err));
    }
  }

  async function handleDeleteSkill(skillId: string) {
    setError("");
    const currentSkill = skills.find((skill) => skill.id === skillId);
    if (!currentSkill || !user || currentSkill.userId !== user.uid) return;

    try {
      if (firebaseEnabled && db) {
        await deleteDoc(doc(db, "skills", skillId));
      }

      const nextSkills = skills.filter((skill) => skill.id !== skillId);
      setSkills(nextSkills);
      if (!firebaseEnabled) {
        localStorage.setItem("skillora-skills", JSON.stringify(nextSkills));
      }
    } catch (err) {
      setError(toMessage(err));
    }
  }

  if (!user) {
    return (
      <AuthScreen
        mode={authMode}
        setMode={setAuthMode}
        loading={loading}
        error={error}
        onLogin={handleLogin}
        onRegister={handleRegister}
        onGoogleLogin={handleGoogleLogin}
      />
    );
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <button className="brand" onClick={() => setPage("dashboard")}>
          <span className="brand-icon">
            <Sparkles size={24} />
          </span>
          <span>
            <strong>Skillora</strong>
            <small>Where Skills Become Currency</small>
          </span>
        </button>
        <nav>
          <NavButton
            icon={<LayoutDashboard />}
            label="Dashboard"
            active={page === "dashboard"}
            onClick={() => setPage("dashboard")}
          />
          <NavButton
            icon={<Store />}
            label="Marketplace"
            active={page === "marketplace"}
            onClick={() => setPage("marketplace")}
          />
          <NavButton
            icon={<ClipboardList />}
            label="Requests"
            active={page === "requests"}
            onClick={() => setPage("requests")}
          />
          <NavButton
            icon={<PlusCircle />}
            label="Add Skill"
            active={page === "add-skill"}
            onClick={() => setPage("add-skill")}
          />
          <NavButton
            icon={<Wallet />}
            label="Wallet"
            active={page === "wallet"}
            onClick={() => setPage("wallet")}
          />
          <NavButton
            icon={<User />}
            label="Profile"
            active={page === "profile"}
            onClick={() => setPage("profile")}
          />
        </nav>
        <button className="logout" onClick={handleLogout}>
          <LogOut size={18} /> Logout
        </button>
      </aside>

      <main className="main-content">
        <header className="topbar">
          <div>
            <p className="eyebrow">
              {firebaseEnabled ? "Firebase connected" : "Demo mode"}
            </p>
            <h1>{pageTitle(page)}</h1>
          </div>
          <div className="user-pill">
            <span>{user.name.charAt(0).toUpperCase()}</span>
            <div>
              <strong>{user.name}</strong>
              <small>{user.credits} credits</small>
            </div>
          </div>
        </header>

        {error && <div className="alert">{error}</div>}

        {page === "dashboard" && (
          <Dashboard
            user={user}
            skills={skills}
            mySkills={mySkills}
            requests={requests}
            setPage={setPage}
          />
        )}
        {page === "marketplace" && (
          <Marketplace
            skills={skills}
            currentUserId={user.uid}
            onRequestSkill={handleRequestSkill}
          />
        )}
        {page === "requests" && (
          <RequestsPage
            user={user}
            requests={requests}
            onUpdateRequestStatus={handleUpdateRequestStatus}
          />
        )}
        {page === "add-skill" && (
          <AddSkill onAddSkill={handleAddSkill} loading={loading} />
        )}
        {page === "wallet" && <WalletPage user={user} />}
        {page === "profile" && (
          <ProfilePage
            user={user}
            mySkills={mySkills}
            onUpdateSkill={handleUpdateSkill}
            onDeleteSkill={handleDeleteSkill}
          />
        )}
      </main>
    </div>
  );
}

function AuthScreen({
  mode,
  setMode,
  loading,
  error,
  onLogin,
  onRegister,
  onGoogleLogin,
}: {
  mode: "login" | "register";
  setMode: (mode: "login" | "register") => void;
  loading: boolean;
  error: string;
  onLogin: (email: string, password: string) => Promise<void>;
  onRegister: (name: string, email: string, password: string) => Promise<void>;
  onGoogleLogin: () => Promise<void>;
}) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("demo@skillora.app");
  const [password, setPassword] = useState("password");

  return (
    <main className="auth-page">
      <section className="hero-panel">
        <div className="hero-badge">
          <Sparkles size={18} /> Cross-platform skill exchange
        </div>
        <h1>Skillora</h1>
        <p>
          Where skills become currency. Offer skills, learn from others, earn
          credits, and build your reputation.
        </p>
        <div className="hero-grid">
          <span>
            <Coins /> Credit wallet
          </span>
          <span>
            <BookOpen /> Skill marketplace
          </span>
          <span>
            <BriefcaseBusiness /> Local exchange
          </span>
        </div>
      </section>

      <form
        className="auth-card"
        onSubmit={(event) => {
          event.preventDefault();
          if (mode === "login") onLogin(email, password);
          else onRegister(name, email, password);
        }}
      >
        <h2>{mode === "login" ? "Welcome back" : "Create account"}</h2>
        <p>
          {firebaseEnabled
            ? "Use Firebase authentication."
            : "Demo mode works instantly without Firebase."}
        </p>
        {mode === "register" && (
          <label>
            Name
            <input
              required
              minLength={2}
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder="Your name"
            />
          </label>
        )}
        <label>
          Email
          <input
            required
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder="you@example.com"
          />
        </label>
        <label>
          Password
          <input
            required
            minLength={6}
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            placeholder="At least 6 characters"
          />
        </label>
        {error && <div className="alert">{error}</div>}
        <button className="primary-btn" disabled={loading}>
          {loading ? "Please wait..." : mode === "login" ? "Login" : "Register"}
        </button>
        <div className="divider">
          <span>or</span>
        </div>
        <button
          type="button"
          className="google-btn"
          disabled={loading}
          onClick={onGoogleLogin}
        >
          <span>G</span> Continue with Google
        </button>
        <button
          type="button"
          className="link-btn"
          onClick={() => setMode(mode === "login" ? "register" : "login")}
        >
          {mode === "login"
            ? "Need an account? Register"
            : "Already have an account? Login"}
        </button>
      </form>
    </main>
  );
}

function Dashboard({
  user,
  skills,
  mySkills,
  requests,
  setPage,
}: {
  user: UserProfile;
  skills: Skill[];
  mySkills: Skill[];
  requests: SkillRequest[];
  setPage: (page: Page) => void;
}) {
  return (
    <section className="content-stack">
      <div className="welcome-card">
        <div>
          <p className="eyebrow">Hello, {user.name}</p>
          <h2>Exchange skills without money</h2>
          <p>
            Start with your 100 Skillora credits. Browse skills or publish what
            you can offer.
          </p>
        </div>
        <button className="primary-btn" onClick={() => setPage("marketplace")}>
          <Search size={18} /> Find skills
        </button>
      </div>
      <div className="stats-grid">
        <Stat
          title="Credits"
          value={user.credits.toString()}
          icon={<Coins />}
        />
        <Stat
          title="Marketplace Skills"
          value={skills.length.toString()}
          icon={<Store />}
        />
        <Stat
          title="My Skills"
          value={mySkills.length.toString()}
          icon={<Star />}
        />
        <Stat
          title="Active Requests"
          value={requests
            .filter((request) =>
              ["pending", "accepted"].includes(request.status),
            )
            .length.toString()}
          icon={<ClipboardList />}
        />
      </div>
      <SectionTitle
        title="Featured skills"
        action="Add your skill"
        onAction={() => setPage("add-skill")}
      />
      <div className="cards-grid">
        {skills.slice(0, 4).map((skill) => (
          <SkillCard
            key={skill.id}
            skill={skill}
            isOwner={skill.userId === user.uid}
          />
        ))}
      </div>
    </section>
  );
}

function Marketplace({
  skills,
  currentUserId,
  onRequestSkill,
}: {
  skills: Skill[];
  currentUserId: string;
  onRequestSkill: (skill: Skill) => Promise<void>;
}) {
  const [category, setCategory] = useState("All");
  const filteredSkills =
    category === "All"
      ? skills
      : skills.filter((skill) => skill.category === category);

  return (
    <section className="content-stack">
      <div className="category-row">
        {["All", ...categories].map((item) => (
          <button
            key={item}
            className={category === item ? "chip active" : "chip"}
            onClick={() => setCategory(item)}
          >
            {item}
          </button>
        ))}
      </div>
      <div className="cards-grid">
        {filteredSkills.map((skill) => (
          <SkillCard
            key={skill.id}
            skill={skill}
            isOwner={skill.userId === currentUserId}
            onRequestSkill={onRequestSkill}
          />
        ))}
      </div>
      {filteredSkills.length === 0 && (
        <EmptyState text="No skills found in this category yet." />
      )}
    </section>
  );
}

function RequestsPage({
  user,
  requests,
  onUpdateRequestStatus,
}: {
  user: UserProfile;
  requests: SkillRequest[];
  onUpdateRequestStatus: (
    requestId: string,
    status: SkillRequestStatus,
  ) => Promise<void>;
}) {
  const incomingRequests = requests.filter(
    (request) => request.providerId === user.uid,
  );
  const outgoingRequests = requests.filter(
    (request) => request.requesterId === user.uid,
  );

  return (
    <section className="content-stack">
      <div className="stats-grid">
        <Stat
          title="Incoming"
          value={incomingRequests.length.toString()}
          icon={<ClipboardList />}
        />
        <Stat
          title="Outgoing"
          value={outgoingRequests.length.toString()}
          icon={<Search />}
        />
        <Stat
          title="Pending"
          value={requests
            .filter((request) => request.status === "pending")
            .length.toString()}
          icon={<Star />}
        />
      </div>

      <SectionTitle title="Incoming requests" />
      <RequestList
        emptyText="No one has requested your skills yet."
        requests={incomingRequests}
        currentUserId={user.uid}
        onUpdateRequestStatus={onUpdateRequestStatus}
      />

      <SectionTitle title="My requests" />
      <RequestList
        emptyText="You have not requested any skills yet."
        requests={outgoingRequests}
        currentUserId={user.uid}
        onUpdateRequestStatus={onUpdateRequestStatus}
      />
    </section>
  );
}

function RequestList({
  requests,
  currentUserId,
  emptyText,
  onUpdateRequestStatus,
}: {
  requests: SkillRequest[];
  currentUserId: string;
  emptyText: string;
  onUpdateRequestStatus: (
    requestId: string,
    status: SkillRequestStatus,
  ) => Promise<void>;
}) {
  if (requests.length === 0) return <EmptyState text={emptyText} />;

  return (
    <div className="cards-grid">
      {requests.map((request) => (
        <RequestCard
          key={request.id}
          request={request}
          currentUserId={currentUserId}
          onUpdateRequestStatus={onUpdateRequestStatus}
        />
      ))}
    </div>
  );
}

function RequestCard({
  request,
  currentUserId,
  onUpdateRequestStatus,
}: {
  request: SkillRequest;
  currentUserId: string;
  onUpdateRequestStatus: (
    requestId: string,
    status: SkillRequestStatus,
  ) => Promise<void>;
}) {
  const isProvider = request.providerId === currentUserId;
  const isRequester = request.requesterId === currentUserId;

  return (
    <article className="skill-card request-card">
      <div className="skill-card-head">
        <span className={`status-badge status-${request.status}`}>
          {request.status}
        </span>
        <strong>{request.credits} credits</strong>
      </div>
      <h3>{request.skillTitle}</h3>
      <p>
        <strong>Requester:</strong> {request.requesterName}
        <br />
        <strong>Provider:</strong> {request.providerName}
      </p>
      <div className="skill-actions">
        {isProvider && request.status === "pending" && (
          <button
            className="secondary-btn"
            onClick={() => onUpdateRequestStatus(request.id, "accepted")}
          >
            Accept
          </button>
        )}
        {isProvider && request.status === "accepted" && (
          <button
            className="secondary-btn"
            onClick={() => onUpdateRequestStatus(request.id, "completed")}
          >
            Complete
          </button>
        )}
        {(isProvider || isRequester) &&
          ["pending", "accepted"].includes(request.status) && (
            <button
              className="danger-btn"
              onClick={() => onUpdateRequestStatus(request.id, "cancelled")}
            >
              Cancel
            </button>
          )}
      </div>
    </article>
  );
}

function AddSkill({
  onAddSkill,
  loading,
}: {
  onAddSkill: (
    skill: Pick<Skill, "title" | "description" | "category" | "credits">,
  ) => Promise<void>;
  loading: boolean;
}) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState(categories[0]);
  const [credits, setCredits] = useState(20);

  return (
    <form
      className="form-card"
      onSubmit={(event) => {
        event.preventDefault();
        onAddSkill({ title, description, category, credits });
      }}
    >
      <h2>Offer a skill</h2>
      <p>
        Create a marketplace listing that other users can request using credits.
      </p>
      <label>
        Skill title
        <input
          required
          minLength={3}
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          placeholder="Graphic Design"
        />
      </label>
      <label>
        Description
        <textarea
          required
          minLength={10}
          value={description}
          onChange={(event) => setDescription(event.target.value)}
          placeholder="Explain what you can teach or provide."
        />
      </label>
      <label>
        Category
        <select
          value={category}
          onChange={(event) => setCategory(event.target.value)}
        >
          {categories.map((item) => (
            <option key={item}>{item}</option>
          ))}
        </select>
      </label>
      <label>
        Credits required
        <input
          required
          type="number"
          min={1}
          value={credits}
          onChange={(event) => setCredits(Number(event.target.value))}
        />
      </label>
      <button className="primary-btn" disabled={loading}>
        {loading ? "Publishing..." : "Publish skill"}
      </button>
    </form>
  );
}

function WalletPage({ user }: { user: UserProfile }) {
  return (
    <section className="content-stack">
      <div className="wallet-card">
        <p className="eyebrow">Current balance</p>
        <h2>{user.credits} credits</h2>
        <p>Credits are transferred after a skill request is completed.</p>
      </div>
      <div className="panel">
        <h3>Transaction history</h3>
        <EmptyState text="Transactions will appear here after request completion is added." />
      </div>
    </section>
  );
}

function ProfilePage({
  user,
  mySkills,
  onUpdateSkill,
  onDeleteSkill,
}: {
  user: UserProfile;
  mySkills: Skill[];
  onUpdateSkill: (
    skillId: string,
    skill: Pick<Skill, "title" | "description" | "category" | "credits">,
  ) => Promise<void>;
  onDeleteSkill: (skillId: string) => Promise<void>;
}) {
  return (
    <section className="content-stack">
      <div className="profile-card">
        <div className="avatar-lg">{user.name.charAt(0).toUpperCase()}</div>
        <div>
          <h2>{user.name}</h2>
          <p>{user.email}</p>
          <div className="meta-row">
            <span>{user.credits} credits</span>
            <span>{user.rating.toFixed(1)} rating</span>
            <span>{firebaseEnabled ? "Firebase" : "Demo"}</span>
          </div>
          <p>
            {user.bio ||
              "Bio, location, and profile image can be added in the next version."}
          </p>
        </div>
      </div>
      <SectionTitle title="My skills" />
      <div className="cards-grid">
        {mySkills.map((skill) => (
          <ManageSkillCard
            key={skill.id}
            skill={skill}
            onUpdateSkill={onUpdateSkill}
            onDeleteSkill={onDeleteSkill}
          />
        ))}
      </div>
      {mySkills.length === 0 && (
        <EmptyState text="You have not added any skills yet." />
      )}
    </section>
  );
}

function ManageSkillCard({
  skill,
  onUpdateSkill,
  onDeleteSkill,
}: {
  skill: Skill;
  onUpdateSkill: (
    skillId: string,
    skill: Pick<Skill, "title" | "description" | "category" | "credits">,
  ) => Promise<void>;
  onDeleteSkill: (skillId: string) => Promise<void>;
}) {
  const [isEditing, setIsEditing] = useState(false);
  const [title, setTitle] = useState(skill.title);
  const [description, setDescription] = useState(skill.description);
  const [category, setCategory] = useState(skill.category);
  const [credits, setCredits] = useState(skill.credits);
  const [isSaving, setIsSaving] = useState(false);

  async function saveChanges() {
    setIsSaving(true);
    await onUpdateSkill(skill.id, { title, description, category, credits });
    setIsSaving(false);
    setIsEditing(false);
  }

  async function deleteSkill() {
    const confirmed = window.confirm(`Delete "${skill.title}"?`);
    if (!confirmed) return;
    await onDeleteSkill(skill.id);
  }

  if (isEditing) {
    return (
      <article className="skill-card manage-skill-card">
        <div className="skill-card-head">
          <span className="category-label">Editing skill</span>
          <button className="icon-btn" onClick={() => setIsEditing(false)}>
            <X size={16} /> Cancel
          </button>
        </div>
        <label>
          Skill title
          <input
            required
            minLength={3}
            value={title}
            onChange={(event) => setTitle(event.target.value)}
          />
        </label>
        <label>
          Description
          <textarea
            required
            minLength={10}
            value={description}
            onChange={(event) => setDescription(event.target.value)}
          />
        </label>
        <label>
          Category
          <select
            value={category}
            onChange={(event) => setCategory(event.target.value)}
          >
            {categories.map((item) => (
              <option key={item}>{item}</option>
            ))}
          </select>
        </label>
        <label>
          Credits required
          <input
            required
            type="number"
            min={1}
            value={credits}
            onChange={(event) => setCredits(Number(event.target.value))}
          />
        </label>
        <button
          className="primary-btn"
          disabled={isSaving || title.length < 3 || description.length < 10}
          onClick={saveChanges}
        >
          {isSaving ? "Saving..." : "Save changes"}
        </button>
      </article>
    );
  }

  return (
    <article className="skill-card manage-skill-card">
      <div className="skill-card-head">
        <span className="category-label">{skill.category}</span>
        <strong>{skill.credits} credits</strong>
      </div>
      <h3>{skill.title}</h3>
      <p>{skill.description}</p>
      <div className="meta-row">
        <span>
          <User size={15} /> {skill.providerName}
        </span>
        <span>
          <Star size={15} /> {skill.rating ? skill.rating.toFixed(1) : "New"}
        </span>
      </div>
      <div className="skill-actions">
        <button className="secondary-btn" onClick={() => setIsEditing(true)}>
          <Edit3 size={16} /> Edit
        </button>
        <button className="danger-btn" onClick={deleteSkill}>
          <Trash2 size={16} /> Delete
        </button>
      </div>
    </article>
  );
}

function SkillCard({
  skill,
  isOwner,
  onRequestSkill,
}: {
  skill: Skill;
  isOwner: boolean;
  onRequestSkill?: (skill: Skill) => Promise<void>;
}) {
  return (
    <article className="skill-card">
      <div className="skill-card-head">
        <span className="category-label">{skill.category}</span>
        <strong>{skill.credits} credits</strong>
      </div>
      <h3>{skill.title}</h3>
      <p>{skill.description}</p>
      <div className="meta-row">
        <span>
          <User size={15} /> {skill.providerName}
        </span>
        <span>
          <Star size={15} /> {skill.rating ? skill.rating.toFixed(1) : "New"}
        </span>
      </div>
      <button
        className="secondary-btn"
        disabled={isOwner || !onRequestSkill}
        onClick={() => onRequestSkill?.(skill)}
      >
        {isOwner ? "Your Skill" : "Request Skill"}
      </button>
    </article>
  );
}

function NavButton({
  icon,
  label,
  active,
  onClick,
}: {
  icon: ReactNode;
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button className={active ? "nav-btn active" : "nav-btn"} onClick={onClick}>
      {icon}
      <span>{label}</span>
    </button>
  );
}

function Stat({
  title,
  value,
  icon,
}: {
  title: string;
  value: string;
  icon: ReactNode;
}) {
  return (
    <div className="stat-card">
      <span>{icon}</span>
      <div>
        <small>{title}</small>
        <strong>{value}</strong>
      </div>
    </div>
  );
}

function SectionTitle({
  title,
  action,
  onAction,
}: {
  title: string;
  action?: string;
  onAction?: () => void;
}) {
  return (
    <div className="section-title">
      <h2>{title}</h2>
      {action && (
        <button className="link-btn" onClick={onAction}>
          {action}
        </button>
      )}
    </div>
  );
}

function EmptyState({ text }: { text: string }) {
  return <div className="empty-state">{text}</div>;
}

function pageTitle(page: Page) {
  const titles: Record<Page, string> = {
    dashboard: "Dashboard",
    marketplace: "Skill Marketplace",
    requests: "Requests",
    "add-skill": "Add Skill",
    wallet: "Credit Wallet",
    profile: "Profile",
  };
  return titles[page];
}

function toMessage(error: unknown) {
  if (error instanceof Error) return error.message;
  return "Something went wrong. Please try again.";
}

function firestoreSetupMessage(error: unknown) {
  const message = toMessage(error);
  if (message.toLowerCase().includes("offline")) {
    return "Firebase Auth is connected, but Firestore is not reachable yet. Create Firestore Database in Firebase Console, then refresh this page.";
  }
  if (message.toLowerCase().includes("permission")) {
    return "Firebase Auth is connected, but Firestore rules are blocking access. Update Firestore rules, then refresh this page.";
  }
  return `Firebase Auth is connected, but Firestore needs setup: ${message}`;
}

export default App;
