import React, { useState, useEffect } from 'react';
import * as XLSX from 'xlsx';
import { emptyDatabase, DAYS } from './mockData.js';
import { supabase } from './supabaseClient.js';

export default function App() {
  const [db, setDb] = useState(emptyDatabase);
  const [currentUser, setCurrentUser] = useState(null);
  const [activeTab, setActiveTab] = useState('attendance');
  const [isConfigOpen, setIsConfigOpen] = useState(false);
  const [toast, setToast] = useState(null);
  const [isLoading, setIsLoading] = useState(false);

  const showToast = (message, type = 'info') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3500);
  };

  // Auth session check
  useEffect(() => {
    if (supabase) {
      supabase.auth.getSession().then(({ data: { session } }) => {
        if (session && session.user) {
          setCurrentUser(session.user);
        }
      });

      const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
        setCurrentUser(session?.user || null);
      });

      return () => {
        if (authListener?.subscription) {
          authListener.subscription.unsubscribe();
        }
      };
    }
  }, []);

  // Fetch real data from Supabase
  const fetchData = async () => {
    if (!supabase || !currentUser) return;
    setIsLoading(true);
    try {
      const [c, s, st, tt, ov, ss, att] = await Promise.all([
        supabase.from('classes').select('*').order('name'),
        supabase.from('subjects').select('*').order('name'),
        supabase.from('students').select('*').order('roll_no'),
        supabase.from('timetable').select('*'),
        supabase.from('timetable_overrides').select('*'),
        supabase.from('attendance_sessions').select('*'),
        supabase.from('attendance').select('*')
      ]);

      setDb({
        classes: c.data || [],
        subjects: s.data || [],
        students: st.data || [],
        timetable: tt.data || [],
        overrides: ov.data || [],
        sessions: ss.data || [],
        attendance: att.data || [],
        teachers: [],
        teacherAssignments: []
      });
    } catch (err) {
      showToast('Error loading Supabase data: ' + err.message, 'error');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (currentUser) {
      fetchData();
    }
  }, [currentUser]);

  const handleLogin = async (email, password) => {
    if (!supabase) {
      showToast('Please configure Supabase connection in .env', 'error');
      return;
    }
    setIsLoading(true);
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      showToast(`Welcome back, ${email}!`, 'success');
    } catch (err) {
      showToast(err.message, 'error');
    } finally {
      setIsLoading(false);
    }
  };

  const handleLogout = async () => {
    if (supabase) {
      await supabase.auth.signOut();
    }
    setCurrentUser(null);
    setDb(emptyDatabase);
    showToast('Logged out', 'info');
  };

  if (!currentUser) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-indigo-950 to-blue-950 flex flex-col items-center justify-center p-4">
        {toast && (
          <div className="fixed top-5 right-5 z-50 px-4 py-3 rounded-xl shadow-lg border text-sm font-medium bg-emerald-50 border-emerald-300 text-emerald-800">
            {toast.message}
          </div>
        )}
        <div className="w-full max-w-md bg-white rounded-3xl p-8 shadow-2xl border border-slate-100 space-y-6">
          <div className="text-center space-y-2">
            <div className="w-14 h-14 rounded-2xl bg-blue-600/10 border border-blue-500/20 text-3xl flex items-center justify-center mx-auto shadow-inner">
              📊
            </div>
            <h1 className="text-2xl font-bold text-slate-800 tracking-tight">AttendEase</h1>
            <p className="text-xs text-slate-500">Live Supabase Period-Wise Attendance & Academic Portal</p>
          </div>

          <form onSubmit={(e) => { e.preventDefault(); handleLogin(e.target.email.value, e.target.password.value); }} className="space-y-4">
            <div>
              <label className="text-xs font-semibold text-slate-700 block mb-1">Email Address</label>
              <input
                name="email"
                type="email"
                placeholder="faculty@college.edu"
                className="w-full text-xs p-3 rounded-xl border border-slate-300 bg-white focus:ring-2 focus:ring-blue-500 outline-none transition"
                required
              />
            </div>
            <div>
              <label className="text-xs font-semibold text-slate-700 block mb-1">Password</label>
              <input
                name="password"
                type="password"
                placeholder="••••••••••••"
                className="w-full text-xs p-3 rounded-xl border border-slate-300 bg-white focus:ring-2 focus:ring-blue-500 outline-none transition"
                required
              />
            </div>
            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 rounded-xl text-xs shadow-md transition"
            >
              {isLoading ? 'Signing In...' : 'Sign In'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col min-h-screen bg-slate-50 text-slate-800">
      <header className="glass-header text-white border-b border-slate-700/60 sticky top-0 z-40 no-print">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-3.5 flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-600/30 border border-blue-400/40 flex items-center justify-center text-xl shadow-inner">
              📊
            </div>
            <div>
              <h1 className="text-lg font-bold tracking-tight text-white flex items-center gap-2">
                AttendEase
                <span className="text-[10px] font-semibold bg-emerald-500/20 text-emerald-300 border border-emerald-400/30 px-2 py-0.5 rounded-full uppercase tracking-wider">
                  Live Supabase
                </span>
              </h1>
              <p className="text-xs text-slate-300">Period-Wise College Attendance & Timetable Management</p>
            </div>
          </div>

          <div className="flex items-center gap-2.5 flex-wrap">
            <span className="text-xs text-slate-300">{currentUser.email}</span>
            <button
              onClick={handleLogout}
              className="px-3.5 py-1.5 text-xs font-semibold rounded-lg bg-red-600/80 hover:bg-red-600 text-white transition shadow-sm"
            >
              Log out
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl w-full mx-auto px-4 sm:px-6 py-6 flex-1">
        {toast && (
          <div className="fixed bottom-5 right-5 z-50 px-4 py-3 rounded-xl shadow-lg border text-sm font-medium bg-emerald-50 border-emerald-300 text-emerald-800">
            {toast.message}
          </div>
        )}

        <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm">
          <h2 className="text-base font-bold text-slate-800 mb-2">Live Database Connected</h2>
          <p className="text-xs text-slate-500">
            Classes in DB: <strong>{db.classes.length}</strong> | Students: <strong>{db.students.length}</strong> | Attendance Records: <strong>{db.attendance.length}</strong>
          </p>
        </div>
      </main>
    </div>
  );
}
