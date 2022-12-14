(*
  File:      Treap.thy
  Authors:   Tobias Nipkow, Max Haslbeck
*)
section \<open>Treaps\<close>
theory Treap
imports
  "HOL-Library.Tree"
  "HOL.Orderings"
begin

definition treap :: "('k::linorder * 'p::linorder) tree \<Rightarrow> bool" where
"treap t = (bst (map_tree fst t) \<and> heap (map_tree snd t))"

abbreviation "keys t \<equiv> set_tree (map_tree fst t)"
abbreviation "prios t \<equiv> set_tree (map_tree snd t)"

function treap_of :: "('k::linorder * 'p::linorder) set \<Rightarrow> ('k * 'p) tree" where
"treap_of KP = (if infinite KP \<or> KP = {} then Leaf else
  let m = arg_min_on snd KP;
      L = {p \<in> KP. fst p < fst m};
      R = {p \<in> KP. fst p > fst m}
  in Node (treap_of L) m (treap_of R))"
by pat_completeness auto
termination
proof (relation "measure card")
  show "wf (measure card)"  by simp
next
  fix KP :: "('a \<times> 'b) set" and m L
  assume KP: "\<not> (infinite KP \<or> KP = {})"
  and m: "m = arg_min_on snd KP"
  and L: "L = {p \<in> KP. fst p < fst m}"
  have "m \<in> KP" using KP arg_min_if_finite(1) m by blast
  thus  "(L, KP) \<in> measure card" using KP L by(auto intro!: psubset_card_mono)
next
  fix KP :: "('a \<times> 'b) set" and m R
  assume KP: "\<not> (infinite KP \<or> KP = {})"
  and m: "m = arg_min_on snd KP"
  and R: "R = {p \<in> KP. fst m < fst p}"
  have "m \<in> KP" using KP arg_min_if_finite(1) m by blast
  thus  "(R, KP) \<in> measure card" using KP R by(auto intro!: psubset_card_mono)
qed

declare treap_of.simps [simp del]

lemma treap_of_unique:
  "\<lbrakk> treap t;  inj_on snd (set_tree t) \<rbrakk>
  \<Longrightarrow> treap_of (set_tree t) = t"
proof(induction "set_tree t" arbitrary: t rule: treap_of.induct)
  case (1 t)
  show ?case
  proof (cases "infinite (set_tree t) \<or> set_tree t = {}")
    case True
    thus ?thesis by(simp add: treap_of.simps)
  next
    case False
    let ?m = "arg_min_on snd (set_tree t)"
    let ?L = "{p \<in> set_tree t. fst p < fst ?m}"
    let ?R = "{p \<in> set_tree t. fst p > fst ?m}"
    obtain l a r where t: "t = Node l a r"
      using False by (cases t) auto
    have "\<forall>kp \<in> set_tree t. snd a \<le> snd kp"
      using "1.prems"(1)
      by(auto simp add: t treap_def ball_Un)
        (metis image_eqI snd_conv tree.set_map)+
    hence "a = ?m"
      by (metis "1.prems"(2) False arg_min_if_finite(1) arg_min_if_finite(2) inj_on_def 
          le_neq_trans t tree.set_intros(2))
    have "treap l" "treap r" using "1.prems"(1) by(auto simp: treap_def t)
    have l: "set_tree l = {p \<in> set_tree t. fst p < fst a}"
      using "1.prems"(1) by(auto simp add: treap_def t ball_Un tree.set_map)
    have r: "set_tree r = {p \<in> set_tree t. fst p > fst a}"
      using "1.prems"(1) by(auto simp add: treap_def t ball_Un tree.set_map)
    have "l = treap_of ?L"
      using "1.hyps"(1)[OF False \<open>a = ?m\<close> l r \<open>treap l\<close>]
        l \<open>a = ?m\<close> "1.prems"(2)
      by (fastforce simp add: inj_on_def)
    have "r = treap_of ?R"
      using "1.hyps"(2)[OF False \<open>a = ?m\<close> l r \<open>treap r\<close>]
        r \<open>a = ?m\<close> "1.prems"(2)
      by (fastforce simp add: inj_on_def)
    have "t = Node (treap_of ?L) ?m (treap_of ?R)"
      using \<open>a = ?m\<close> \<open>l = treap_of ?L\<close> \<open>r = treap_of ?R\<close> by(subst t) simp
    thus ?thesis using False
      by (subst treap_of.simps) simp
  qed
qed

lemma treap_unique:
  "\<lbrakk> treap t1; treap t2; set_tree t1 = set_tree t2; inj_on snd (set_tree t1) \<rbrakk>
  \<Longrightarrow> t1 = t2"
  for t1 t2 :: "('k::linorder * 'p::linorder) tree"
by (metis treap_of_unique)

fun ins :: "'k::linorder \<Rightarrow> 'p::linorder \<Rightarrow> ('k \<times> 'p) tree \<Rightarrow> ('k \<times> 'p) tree" where
"ins k p Leaf = \<langle>Leaf, (k,p), Leaf\<rangle>" |
"ins k p \<langle>l, (k1,p1), r\<rangle> =
  (if k < k1 then
     (case ins k p l of
       \<langle>l2, (k2,p2), r2\<rangle> \<Rightarrow>
         if p1 \<le> p2 then \<langle>\<langle>l2, (k2,p2), r2\<rangle>, (k1,p1), r\<rangle>
         else \<langle>l2, (k2,p2), \<langle>r2, (k1,p1), r\<rangle>\<rangle>)
   else
   if k > k1 then
     (case ins k p r of
       \<langle>l2, (k2,p2), r2\<rangle> \<Rightarrow>
         if p1 \<le> p2 then \<langle>l, (k1,p1), \<langle>l2, (k2,p2), r2\<rangle>\<rangle>
         else \<langle>\<langle>l, (k1,p1), l2\<rangle>, (k2,p2), r2\<rangle>)
   else \<langle>l, (k1,p1), r\<rangle>)"


lemma ins_neq_Leaf: "ins k p t \<noteq> \<langle>\<rangle>"
  by (induction t rule: ins.induct) (auto split: tree.split)

lemma keys_ins: "keys (ins k p t) = Set.insert k (keys t)"
proof (induction t rule: ins.induct)
  case 2
  then show ?case
    by (simp add: ins_neq_Leaf split: tree.split prod.split) (safe; fastforce)
qed (simp)

lemma prios_ins: "prios (ins k p t) \<subseteq> {p} \<union> prios t"
apply(induction t rule: ins.induct)
 apply simp
  apply (simp add: ins_neq_Leaf split: tree.split prod.split)
  by (safe; fastforce)

lemma prios_ins': "k \<notin> keys t \<Longrightarrow> prios (ins k p t) = {p} \<union> prios t"
apply(induction t rule: ins.induct)
 apply simp
  apply (simp add: ins_neq_Leaf split: tree.split prod.split)
  by (safe; fastforce)

lemma set_tree_ins: "set_tree (ins k p t) \<subseteq> {(k,p)} \<union> set_tree t"
  by (induction t rule: ins.induct) (auto simp add: ins_neq_Leaf split: tree.split prod.split)
    
lemma set_tree_ins': "k \<notin> keys t \<Longrightarrow>  {(k,p)} \<union> set_tree t \<subseteq> set_tree (ins k p t)"
  by (induction t rule: ins.induct) (auto simp add: ins_neq_Leaf split: tree.split prod.split)

lemma set_tree_ins_eq: "k \<notin> keys t \<Longrightarrow> set_tree (ins k p t) = {(k,p)} \<union> set_tree t"
  using set_tree_ins set_tree_ins' by blast

lemma prios_ins_special:
  "\<lbrakk> ins k p t = Node l (k',p') r;  p' = p; p \<in> prios r \<union> prios l \<rbrakk>
  \<Longrightarrow> p \<in> prios t"
  by (induction k p t arbitrary: l k' p' r rule: ins.induct)
     (fastforce simp add: ins_neq_Leaf split: tree.splits prod.splits if_splits)+

lemma treap_NodeI:
  "\<lbrakk> treap l; treap r;
     \<forall>k' \<in> keys l. k' < k; \<forall>k' \<in> keys r. k < k';
     \<forall>p' \<in> prios l. p \<le> p'; \<forall>p' \<in> prios r. p \<le> p' \<rbrakk>
  \<Longrightarrow> treap (Node l (k,p) r)"
 by (auto simp: treap_def)

lemma treap_rotate1:
  assumes "treap l2" "treap r2" "treap r" "\<not> p1 \<le> p2" "k < k1" and
  ins: "ins k p l = Node l2 (k2,p2) r2" and treap_ins: "treap (ins k p l)"
  and treap: "treap \<langle>l, (k1, p1), r\<rangle>"
  shows "treap (Node l2 (k2,p2) (Node r2 (k1,p1) r))"
proof(rule treap_NodeI[OF \<open>treap l2\<close> treap_NodeI[OF \<open>treap r2\<close> \<open>treap r\<close>]])
  from keys_ins[of k p l] have 1: "keys r2 \<subseteq> {k} \<union> keys l" by(auto simp: ins)
  from treap have 2: "\<forall>k'\<in>keys l. k' < k1" by (simp add: treap_def)
  show "\<forall>k'\<in>keys r2. k' < k1" using 1 2 \<open>k < k1\<close> by blast
next
  from treap have 2: "\<forall>p'\<in>prios l. p1 \<le> p'" by (simp add: treap_def)
  show "\<forall>p'\<in>prios r2. p1 \<le> p'"
  proof
    fix p' assume "p' \<in> prios r2"
    hence "p' = p \<or> p' \<in> prios l" using prios_ins[of k p l] ins by auto
    thus "p1 \<le> p'"
    proof
      assume [simp]: "p' = p"
      have "p2 = p \<or> p2 \<in> prios l" using prios_ins[of k p l] ins by simp
      thus "p1 \<le> p'"
      proof
        assume "p2 = p"
        thus "p1 \<le> p'"
          using prios_ins_special[OF ins] \<open>p' \<in> prios r2\<close> 2 by auto
      next
        assume "p2 \<in> prios l"
        thus "p1 \<le> p'" using 2 \<open>\<not> p1 \<le> p2\<close> by blast
      qed
    next
      assume "p' \<in> prios l"
      thus "p1 \<le> p'" using 2 by blast
    qed
  qed
next
  have "k2 = k \<or> k2 \<in> keys l" using keys_ins[of k p l] ins by (auto)
  hence 1: "k2 < k1"
  proof
    assume "k2 = k" thus "k2 < k1" using \<open>k < k1\<close> by simp
  next
    assume "k2 \<in> keys l"
    thus "k2 < k1" using treap by (auto simp: treap_def)
  qed
  have 2: "\<forall>k'\<in>keys r2. k2 < k'"
    using treap_ins by(simp add: ins treap_def)
  have 3: "\<forall>k'\<in>keys r. k2 < k'"
    using 1 treap by(auto simp: treap_def)
  show "\<forall>k'\<in>keys \<langle>r2, (k1, p1), r\<rangle>. k2 < k'" using 1 2 3 by auto
next
  show "\<forall>p'\<in>prios \<langle>r2, (k1, p1), r\<rangle>. p2 \<le> p'"
    using ins treap_ins treap \<open>\<not> p1 \<le> p2\<close> by (auto simp: treap_def ball_Un)
qed (use ins treap_ins treap in \<open>auto simp: treap_def ball_Un\<close>)


lemma treap_rotate2:
  assumes "treap l" "treap l2" "treap r2" "\<not> p1 \<le> p2" "k1 < k" and
  ins: "ins k p r = Node l2 (k2,p2) r2" and treap_ins: "treap (ins k p r)"
  and treap: "treap \<langle>l, (k1, p1), r\<rangle>"
  shows "treap (Node (Node l (k1,p1) l2) (k2,p2) r2)"
proof(rule treap_NodeI[OF treap_NodeI[OF \<open>treap l\<close> \<open>treap l2\<close>] \<open>treap r2\<close>])
  from keys_ins[of k p r] have 1: "keys l2 \<subseteq> {k} \<union> keys r" by(auto simp: ins)
  from treap have 2: "\<forall>k'\<in>keys r. k1 < k'" by (simp add: treap_def)
  show "\<forall>k'\<in>keys l2. k1 < k'" using 1 2 \<open>k1 < k\<close> by blast
next
  from treap have 2: "\<forall>p'\<in>prios r. p1 \<le> p'" by (simp add: treap_def)
  show "\<forall>p'\<in>prios l2. p1 \<le> p'"
  proof
    fix p' assume "p' \<in> prios l2"
    hence "p' = p \<or> p' \<in> prios r" using prios_ins[of k p r] ins by auto
    thus "p1 \<le> p'"
    proof
      assume [simp]: "p' = p"
      have "p2 = p \<or> p2 \<in> prios r" using prios_ins[of k p r] ins by simp
      thus "p1 \<le> p'"
      proof
        assume "p2 = p"
        thus "p1 \<le> p'"
          using prios_ins_special[OF ins] \<open>p' \<in> prios l2\<close> 2 by auto
      next
        assume "p2 \<in> prios r"
        thus "p1 \<le> p'" using 2 \<open>\<not> p1 \<le> p2\<close> by blast
      qed
    next
      assume "p' \<in> prios r"
      thus "p1 \<le> p'" using 2 by blast
    qed
  qed
next
  have "k2 = k \<or> k2 \<in> keys r" using keys_ins[of k p r] ins by (auto)
  hence 1: "k1 < k2"
  proof
    assume "k2 = k" thus "k1 < k2" using \<open>k1 < k\<close> by simp
  next
    assume "k2 \<in> keys r"
    thus "k1 < k2" using treap by (auto simp: treap_def)
  qed
  have 2: "\<forall>k'\<in>keys l. k' < k2" using 1 treap by(auto simp: treap_def)
  have 3: "\<forall>k'\<in>keys l2. k' < k2"
    using treap_ins by(auto simp: ins treap_def)
  show "\<forall>k'\<in>keys \<langle>l, (k1, p1), l2\<rangle>. k' < k2" using 1 2 3 by auto
next
  show "\<forall>p'\<in>prios \<langle>l, (k1, p1), l2\<rangle>. p2 \<le> p'"
    using ins treap_ins treap \<open>\<not> p1 \<le> p2\<close> by (auto simp: treap_def ball_Un)
qed (use ins treap_ins treap in \<open>auto simp: treap_def ball_Un\<close>)

lemma treap_ins: "treap t \<Longrightarrow> treap (ins k p t)"
proof(induction t rule: ins.induct)
  case 1 thus ?case by (simp add: treap_def)
next
  case (2 k p l k1 p1 r)
  have "treap l" "treap r"
    using "2.prems" by(auto simp: treap_def tree.set_map)
  show ?case
  proof cases
    assume "k < k1"
    obtain l2 k2 p2 r2 where ins: "ins k p l = Node l2 (k2,p2) r2"
      by (metis ins_neq_Leaf neq_Leaf_iff prod.collapse)
    note treap_ins = "2.IH"(1)[OF \<open>k < k1\<close> \<open>treap l\<close>]
    hence "treap l2" "treap r2" using ins by (auto simp add: treap_def)
    show ?thesis
    proof cases
      assume "p1 \<le> p2"
      have "treap (Node (Node l2 (k2,p2) r2) (k1,p1) r)"
        apply(rule treap_NodeI[OF treap_ins[unfolded ins] \<open>treap r\<close>])
        using ins treap_ins \<open>k < k1\<close> "2.prems" keys_ins[of k p l]
        by (auto simp add: treap_def ball_Un order_trans[OF \<open>p1 \<le> p2\<close>])
      thus ?thesis using \<open>k < k1\<close> ins \<open>p1 \<le> p2\<close> by simp
    next
      assume "\<not> p1 \<le> p2"
      have "treap (Node l2 (k2,p2) (Node r2 (k1,p1) r))"
        by(rule treap_rotate1[OF \<open>treap l2\<close> \<open>treap r2\<close>  \<open>treap r\<close> \<open>\<not> p1 \<le> p2\<close>
            \<open>k < k1\<close> ins treap_ins "2.prems"])
      thus ?thesis using \<open>k < k1\<close> ins \<open>\<not> p1 \<le> p2\<close> by simp
    qed
  next
    assume "\<not> k < k1"
    show ?thesis
    proof cases
    assume "k > k1"
    obtain l2 k2 p2 r2 where ins: "ins k p r = Node l2 (k2,p2) r2"
      by (metis ins_neq_Leaf neq_Leaf_iff prod.collapse)
    note treap_ins = "2.IH"(2)[OF \<open>\<not> k < k1\<close> \<open>k > k1\<close> \<open>treap r\<close>]
    hence "treap l2" "treap r2" using ins by (auto simp add: treap_def)
    have fst: "\<forall>k' \<in> set_tree (map_tree fst (ins k p r)).
                 k' = k \<or> k' \<in> set_tree (map_tree fst r)"
      by(simp add: keys_ins)
    show ?thesis
    proof cases
      assume "p1 \<le> p2"
      have "treap (Node l (k1,p1) (ins k p r))"
        apply(rule treap_NodeI[OF \<open>treap l\<close> treap_ins])
        using ins treap_ins \<open>k > k1\<close> "2.prems" keys_ins[of k p r]
        by (auto simp: treap_def ball_Un order_trans[OF \<open>p1 \<le> p2\<close>])
      thus ?thesis using \<open>\<not> k < k1\<close> \<open>k > k1\<close> ins \<open>p1 \<le> p2\<close> by simp
    next
      assume "\<not> p1 \<le> p2"
      have "treap (Node (Node l (k1,p1) l2) (k2,p2) r2)"
        by(rule treap_rotate2[OF \<open>treap l\<close> \<open>treap l2\<close> \<open>treap r2\<close> \<open>\<not> p1 \<le> p2\<close>
             \<open>k1 < k\<close> ins treap_ins "2.prems"])
      thus ?thesis using \<open>\<not> k < k1\<close>  \<open>k > k1\<close> ins \<open>\<not> p1 \<le> p2\<close> by simp
    qed
    next
      assume "\<not> k > k1"
      hence "k = k1" using \<open>\<not> k < k1\<close> by auto
      thus ?thesis using "2.prems" by(simp)
    qed
  qed  
qed

lemma treap_of_set_tree_unique:
  "\<lbrakk> finite A; inj_on fst A; inj_on snd A \<rbrakk>
  \<Longrightarrow> set_tree (treap_of A) = A"  
proof(induction "A" rule: treap_of.induct)
  case (1 A)
  note IH = 1
  show ?case
  proof (cases "infinite A \<or> A = {}")
    assume "infinite A \<or> A = {}"
    with IH show ?thesis by (simp add: treap_of.simps)
  next
    assume not_inf_or_empty: "\<not> (infinite A \<or> A = {})"
    let ?m = "arg_min_on snd A"
    let ?L = "{p \<in> A. fst p < fst ?m}"
    let ?R = "{p \<in> A. fst p > fst ?m}"
    obtain l a r where t: "treap_of A = Node l a r"
      using not_inf_or_empty
      by (cases "treap_of A") (auto simp: Let_def elim!: treap_of.elims split: if_splits)
    have [simp]: "inj_on fst {p \<in> A. fst p < fst (arg_min_on snd A)}"
                 "inj_on snd {p \<in> A. fst p < fst (arg_min_on snd A)}"
                 "inj_on fst {p \<in> A. fst (arg_min_on snd A) < fst p}"
                 "inj_on snd {p \<in> A. fst (arg_min_on snd A) < fst p}"
      using IH by (auto intro: inj_on_subset)
    have lr: "l = treap_of ?L" "r = treap_of ?R"
      using t by (auto simp: Let_def elim: treap_of.elims split: if_splits)
    then have l: "set_tree l = ?L"
       using not_inf_or_empty IH by auto
     have "r = treap_of ?R"
       using t by (auto simp: Let_def elim: treap_of.elims split: if_splits)
    then have r: "set_tree r = ?R"
      using not_inf_or_empty IH(2) by (auto)
    have a: "a = ?m"
      using t by (elim treap_of.elims) (simp add: Let_def split: if_splits)
    have "a \<noteq> fst (arg_min_on snd A)" if "(a,b) \<in> A" "(a, b) \<noteq> arg_min_on snd A" for a b
      using IH(4,5) that not_inf_or_empty arg_min_if_finite(1) inj_on_eq_iff by fastforce
    then have "a < fst (arg_min_on snd A)" 
       if "(a,b) \<in> A" "(a, b) \<noteq> arg_min_on snd A" "fst (arg_min_on snd A) \<ge> a" for a b
      using le_neq_trans that by auto
    moreover have "arg_min_on snd A \<in> A"
      using not_inf_or_empty arg_min_if_finite by auto
    ultimately have A: "A = {?m} \<union> ?L \<union> ?R"
      by auto
    show ?thesis using l r a A t by force
  qed
qed

lemma treap_of_subset: "set_tree (treap_of A) \<subseteq> A"
proof(induction "A" rule: treap_of.induct)
  case (1 A)
  note IH = 1
  show ?case
  proof (cases "infinite A \<or> A = {}")
    assume "infinite A \<or> A = {}"
    with IH show ?thesis by (simp add: treap_of.simps)
  next
    assume not_inf_or_empty: "\<not> (infinite A \<or> A = {})"
    let ?m = "arg_min_on snd A"
    let ?L = "{p \<in> A. fst p < fst ?m}"
    let ?R = "{p \<in> A. fst p > fst ?m}"
    obtain l a r where t: "treap_of A = Node l a r"
      using not_inf_or_empty by (cases "treap_of A")
                                (auto simp add: Let_def  elim!: treap_of.elims split: if_splits)
    have "l = treap_of ?L" "r = treap_of ?R"
      using t by (auto simp: Let_def elim: treap_of.elims split: if_splits)
    have "set_tree l \<subseteq> ?L" "set_tree r \<subseteq> ?R"
    proof -
      have "set_tree (treap_of {p \<in> A. fst p < fst (arg_min_on snd A)})
            \<subseteq> {p \<in> A. fst p < fst (arg_min_on snd A)}"
        by (rule IH) (use not_inf_or_empty in auto)
      then show "set_tree l \<subseteq> ?L"
        using \<open>l = treap_of ?L\<close> by auto
    next
      have "set_tree (treap_of {p \<in> A. fst (arg_min_on snd A) < fst p})
            \<subseteq> {p \<in> A. fst (arg_min_on snd A) < fst p}"
        by (rule IH) (use not_inf_or_empty in auto)
      then show "set_tree r \<subseteq> ?R"
        using \<open>r = treap_of ?R\<close> by auto
    qed
    moreover have "a = ?m"
      using t by (auto elim!: treap_of.elims simp add: Let_def split: if_splits)
    moreover have "{?m} \<union> ?L \<union> ?R \<subseteq> A"
      using not_inf_or_empty arg_min_if_finite by auto
    ultimately show ?thesis by (auto simp add: t)
  qed
qed

lemma treap_treap_of:
  "treap (treap_of A)"
proof(induction "A" rule: treap_of.induct)
  case (1 A)
  show ?case
  proof (cases "infinite A \<or> A = {}")
    case True
    with 1 show ?thesis by (simp add: treap_of.simps treap_def)
  next
    case False
    let ?m = "arg_min_on snd A"
    let ?L = "{p \<in> A. fst p < fst ?m}"
    let ?R = "{p \<in> A. fst p > fst ?m}"
    obtain l a r where t: "treap_of A = Node l a r"
      using False by (cases "treap_of A") (auto simp: Let_def elim!: treap_of.elims split: if_splits)
    have l: "l = treap_of ?L"
      using t by (auto simp: Let_def elim: treap_of.elims split: if_splits)
    then have treap_l: "treap l"
      using False by (auto intro: 1) 
    from l have keys_l: "keys l \<subseteq> fst ` ?L"
      by (auto simp add: tree.set_map intro!: image_mono treap_of_subset)
    have r: "r = treap_of ?R"
      using t by (auto simp: Let_def elim: treap_of.elims split: if_splits)
    then have treap_r: "treap r"
      using False by (auto intro: 1) 
    from r have keys_r: "keys r \<subseteq> fst ` ?R"
      by (auto simp add: tree.set_map intro!: image_mono treap_of_subset)
    have prios: "prios l \<subseteq> snd ` A" "prios r \<subseteq> snd ` A"
      using l r treap_of_subset image_mono by (auto simp add: tree.set_map)
    have a: "a = ?m"
      using t by(auto simp: Let_def elim: treap_of.elims split: if_splits)
    have prios_l: "\<And>x. x \<in> prios l \<Longrightarrow> snd a \<le> x"
      by (drule rev_subsetD[OF _ prios(1)]) (use arg_min_least a False in fast)
    have prios_r: "\<And>x. x \<in> prios r \<Longrightarrow> snd a \<le> x"
      by (drule rev_subsetD[OF _ prios(2)]) (use arg_min_least a False in fast)
    show ?thesis
      using prios_r prios_l treap_l treap_r keys_l keys_r a 
      by (auto simp add: t treap_def dest: rev_subsetD[OF _ keys_l] rev_subsetD[OF _ keys_r])
    qed
qed

lemma treap_Leaf: "treap \<langle>\<rangle>"
  by (simp add: treap_def)

lemma foldl_ins_treap: "treap t \<Longrightarrow> treap (foldl (\<lambda>t' (x, p). ins x p t') t xs)"
  using treap_ins by (induction xs arbitrary: t) auto

lemma foldl_ins_set_tree: 
  assumes "inj_on fst (set ys)" "inj_on snd (set ys)" "distinct ys" "fst ` (set ys) \<inter> keys t = {}"
  shows "set_tree (foldl (\<lambda>t' (x, p). ins x p t') t ys) = set ys \<union> set_tree t"
  using assms
  by (induction ys arbitrary: t) (auto simp add: case_prod_beta' set_tree_ins_eq keys_ins)

lemma foldl_ins_treap_of:
  assumes "distinct ys" "inj_on fst (set ys)" "inj_on snd (set ys)"
 shows "(foldl (\<lambda>t' (x, p). ins x p t') Leaf ys) = treap_of (set ys)"
  using assms by (intro treap_unique) (auto simp: treap_Leaf foldl_ins_treap foldl_ins_set_tree 
                                                  treap_treap_of treap_of_set_tree_unique)



fun cont:: "'k \<Rightarrow> 'p \<Rightarrow> ('k \<times> 'p) tree \<Rightarrow> bool" where
"cont k p \<langle>\<rangle> = False" |
"cont k p \<langle>l, (k1, p1), r\<rangle> = ((k = k1 \<and> p = p1) \<or> (cont k p l) \<or> (cont k p r))"

lemma cont_then_in_keys: "\<lbrakk>treap t; cont k p t\<rbrakk> \<Longrightarrow> k \<in> keys t"
  apply(induction t)
  apply(auto simp: treap_def tree.set_map)
  done

lemma cont_then_in_prios: "\<lbrakk>treap t; cont k p t\<rbrakk> \<Longrightarrow> p \<in> prios t"
  apply(induction t)
  apply(auto simp: treap_def tree.set_map)
  done


lemma sub_treap:
  assumes "treap \<langle>l, (k, p), r\<rangle>"
  shows "(treap l) \<and> (treap r)"
proof
  have 0: "bst (map_tree fst \<langle>l, (k, p), r\<rangle>)" using assms(1) by (auto simp add: treap_def)
  have 1: "heap (map_tree snd \<langle>l, (k, p), r\<rangle>)" using assms(1) by (auto simp add: treap_def)
  show "treap l" using 0 1 by (auto simp add: treap_def)
  show  "treap r" using 0 1 by (auto simp add: treap_def)
qed


lemma ins_cont:
  assumes  "treap t"
  shows "cont k p (ins k p t) \<or> k \<in> keys t"
proof(induction t rule: ins.induct)
  case (1 k p)
  then show ?case by (auto)
next
  case (2 k p l k1 p1 r)
  obtain  l2 k2 p2 r2 where ins: "ins k p l = Node l2 (k2,p2) r2"
    by (metis ins_neq_Leaf neq_Leaf_iff prod.collapse)
  obtain  l3 k3 p3 r3 where ins_r: "ins k p r = Node l3 (k3,p3) r3"
      by (metis ins_neq_Leaf neq_Leaf_iff prod.collapse)
  then show ?case
  proof (cases "k < k1")
    case True
    then show ?thesis using  ins "2.IH" by (auto)
  next
    case 0: False
    then show ?thesis 
    proof (cases "k = k1")
      case True
      then show ?thesis using  "2.IH" by (auto)
    next
      case False
      then have "k > k1" using 0 by (auto)
      then show ?thesis using ins_r "2.IH"  by (auto)
    qed
  qed
qed

lemma cont_ins_same: "\<lbrakk>treap t; cont k p t\<rbrakk> \<Longrightarrow> ins k p t = t"
proof(induction t rule: ins.induct)
  case (1 k p)
  then show ?case by (auto)
next
  case (2 k p l k1 p1 r)
  then show ?case
  proof (cases "k = k1")
    case True
    then show ?thesis by (auto)
  next
    case f: False
    then show ?thesis 
    proof (cases "k < k1")
      case 0: True
      then have "\<forall> kr. (kr \<in> keys r) \<longrightarrow> kr > k" 
        using "2.prems" 
        by (auto  simp: treap_def tree.set_map)
      then have "k \<notin> keys r" by (auto simp: treap_def tree.set_map)
      then have "\<not> cont k p r" 
        using "2.prems" cont_then_in_keys[of r k p] sub_treap
        by (auto)
      then have "cont k p l" 
        using 0 "2.IH" "2.prems" 
        by (auto simp: treap_def tree.set_map)
      then have a: "ins k p l = l" using 0 sub_treap[of l k1 p1 r] "2.IH" "2.prems" by (auto)
      obtain l2 k2 p2 r2 where get_p2: "ins k p l =  \<langle>l2, (k2, p2), r2\<rangle>" 
        by  (metis ins_neq_Leaf neq_Leaf_iff prod.collapse)
      have "p2 \<in> prios l" using get_p2 a by (auto  simp: treap_def  tree.set_map)
      then have "p2 \<ge> p1" using get_p2 "2.prems" by (auto simp: treap_def  tree.set_map)
      then show ?thesis using 0 a get_p2 sub_treap[of l k1 p1 r] "2.IH" "2.prems" by (auto)
    next
      case 3: False
      then have "\<forall> kr. (kr \<in> keys l) \<longrightarrow> kr < k" 
        using "2.prems" 
        by (auto  simp: treap_def tree.set_map)
      then have "k \<notin> keys l" by (auto simp: treap_def tree.set_map)
      then have "\<not> cont k p l" 
        using "2.prems" cont_then_in_keys[of l k p] sub_treap
        by (auto)
      then have "cont k p r" 
        using 3 f "2.IH" "2.prems" 
        by (auto simp: treap_def tree.set_map)
      then have a: "ins k p r = r" using 3 f sub_treap[of l k1 p1 r] "2.IH" "2.prems" by (auto)
      obtain l2 k2 p2 r2 where get_p2: "ins k p r =  \<langle>l2, (k2, p2), r2\<rangle>" 
        by  (metis ins_neq_Leaf neq_Leaf_iff prod.collapse)
      have "p2 \<in> prios r" using get_p2 a by (auto  simp: treap_def  tree.set_map)
      then have "p2 \<ge> p1" using get_p2 "2.prems" by (auto simp: treap_def  tree.set_map)
      then show ?thesis using 3 f a get_p2 sub_treap[of l k1 p1 r] "2.IH" "2.prems" by (auto)
    qed
  qed
qed

lemma cont_subtreap:
 "\<lbrakk>\<not> cont k p r; \<not> cont k p l; k \<noteq>  k1 \<or> p \<noteq> p1\<rbrakk> \<Longrightarrow> \<not> cont k p \<langle>l, (k1, p1),r \<rangle> "
  apply(auto)
  done


fun disjoint_treap:: " ('k \<times>'p::linorder) tree \<Rightarrow> ('k \<times> 'p) tree \<Rightarrow> bool" where
"disjoint_treap \<langle>\<rangle> t2 = True" |
"disjoint_treap \<langle>l, (k, p), r\<rangle> t2 = ((cont k p t2) \<and> (disjoint_treap l t2) \<and> (disjoint_treap r t2))"

fun merge :: "('k::linorder \<times> 'p::linorder) tree \<Rightarrow> ('k \<times> 'p) tree \<Rightarrow> ('k \<times> 'p) tree" where
"merge t Leaf = t" |
"merge Leaf t = t" |
"merge \<langle>l1, (k1,p1), r1\<rangle>  \<langle>l2, (k2, p2), r2\<rangle> = 
 (if p1 < p2 then
    \<langle>l1, (k1,p1), merge r1  \<langle>l2, (k2, p2), r2 \<rangle>\<rangle>
  else
     \<langle>merge \<langle>l1, (k1,p1), r1\<rangle> l2, (k2, p2), r2\<rangle>)
"

lemma subbst_is_bst:
   "\<lbrakk>bst  \<langle>l, (k), r\<rangle> \<rbrakk> \<Longrightarrow> bst l"
  apply (auto)
  done

lemma subheap_is_heap:
   "\<lbrakk>heap  \<langle>l, (p), r\<rangle> \<rbrakk> \<Longrightarrow> heap l \<and> heap r"
  apply (auto)
  done

lemma bst_union:
  assumes "bst l" "bst r"
    "disjoint (set_tree l) (set_tree r)"
    "\<forall>k' \<in> set_tree l.  k' < k"
    "\<forall>k'' \<in> set_tree r. k < k''"
  shows  "bst  \<langle>l, k, r\<rangle>"
  using assms by (auto)

lemma heap_union:
  assumes "heap l" "heap r"
    "disjoint (set_tree l) (set_tree r)"
    "\<forall>p' \<in> set_tree l.  p' > p"
    "\<forall>p'' \<in> set_tree r. p'' > p"
  shows  "heap  \<langle>l, p, r\<rangle>"
  using assms by (auto)


lemma submap_fst_is_map:
"\<lbrakk>treap  \<langle>l, (k,p), r\<rangle>;  \<langle>a, b, c\<rangle> = (map_tree fst \<langle>l, (k,p), r\<rangle>)\<rbrakk> \<Longrightarrow>  a = map_tree fst l \<and> b = k \<and> c = map_tree fst r"
  apply(auto)
  done

lemma submap_snd_is_map:
"\<lbrakk>treap  \<langle>l, (k,p), r\<rangle>;  \<langle>a, b, c\<rangle> = (map_tree snd \<langle>l, (k,p), r\<rangle>)\<rbrakk> \<Longrightarrow>  a = map_tree snd l \<and> b = p \<and> c = map_tree snd r"
  apply(auto)
  done

 
lemma subset_disj:
 "a  \<subseteq> b \<and> disjnt b c \<Longrightarrow> disjnt a c"
  using disjnt_def by (blast)


lemma treap_union:
  assumes   "treap l" "treap r"
    "\<forall>k' \<in> keys l. k' < k"
    "\<forall>k'' \<in> keys r. k < k''"  
    "\<forall>p' \<in> prios l. p' \<ge> p"
    " \<forall>p'' \<in> prios r. p'' \<ge> p"
  shows "treap  \<langle>l, (k, p), r\<rangle>"
proof -
  obtain bst_l where get_bst_l: "bst_l = (map_tree fst l)" by (auto)
  obtain bst_r where get_bst_r: "bst_r = (map_tree fst r)" by (auto)
  have 0: "bst bst_l" using assms(1) get_bst_l  by (auto simp: treap_def)
  have 1: "bst bst_r" using assms(2) get_bst_r  by (auto simp: treap_def)
  have 2: "bst  \<langle>bst_l, k, bst_r\<rangle>"  using 0 1 get_bst_l get_bst_r assms(3) assms(4)  bst_union by (auto simp add: treap_def tree.set_map)

  obtain heap_l where get_heap_l: "heap_l = (map_tree snd l)" by (auto)
  obtain heap_r where get_heap_r: "heap_r = (map_tree snd r)" by (auto)
  have 3: "heap heap_l" using assms(1) get_heap_l  by (auto simp: treap_def)
  have 4: "heap heap_r" using assms(2) get_heap_r  by (auto simp: treap_def)
  have 5: "heap  \<langle>heap_l, p, heap_r\<rangle>"  using 3 4 get_heap_l get_heap_r assms(5) assms(6) heap_union by (auto simp add: treap_def tree.set_map)

 
  show  "treap  \<langle>l, (k, p), r\<rangle>" using 2 5 get_bst_l get_bst_r get_heap_l get_heap_r by (auto simp add: treap_def) 
qed

lemma merge_treap_key_preserve:
" keys (merge t1 t2) = keys  t1 \<union> keys t2"
  apply(induction t1 t2 rule: merge.induct )
  apply(auto)
  done


lemma merge_treap_prios_preserve:
" prios (merge t1 t2) = prios  t1 \<union> prios t2"
  apply(induction t1 t2 rule: merge.induct )
  apply(auto)
  done


lemma merge_treap:
  "\<lbrakk>treap l; treap r ;(\<forall>k' \<in> keys l. \<forall>k'' \<in> keys r. k' < k'') \<rbrakk> \<Longrightarrow> treap (merge l r)"
proof(induction l r  rule: merge.induct)
  case (1 t)
  have "treap t" using "1.prems"(1) by (auto)
  then show ?case by (auto)
next
  case (2 v va vb)
  then show ?case using "2.prems"(2) by (auto)
next
  case (3 l1 k1 p1 r1 l2 k2 p2 r2)
  then show ?case
  proof (cases "p1 < p2")
      case 4: True
      obtain treap_r where get_treap_r: "treap_r = merge r1  \<langle>l2, (k2, p2), r2 \<rangle>" by (auto)
      obtain t2 where get_t2: "t2 =  \<langle>l2, (k2, p2), r2 \<rangle>" by (auto)
      have treap_r_is_treap: "treap treap_r"
        using 4 "3.IH"(1) "3.prems" get_treap_r sub_treap[of l1 k1 p1 r1]
        by (auto simp: treap_def tree.set_map)

      have keys_1: "\<forall>k' \<in> keys l1.  k' < k1" using "3.prems" by (auto simp: treap_def tree.set_map)

      have "\<forall>k''\<in>keys treap_r. k'' \<in> keys r1 \<or> k'' \<in> keys t2" 
        using get_treap_r  get_t2 merge_treap_key_preserve[of r1 t2] by auto
      moreover have "\<forall>k''\<in>keys t2. k1 < k''" using get_t2 "3.prems" by (auto)
      moreover have "\<forall>k''\<in>keys r1. k1 < k''" using "3.prems"(1) by (auto simp: treap_def)
      ultimately have keys_2: "\<forall>k''\<in>keys treap_r. k1 < k''" by (auto)

      have l1_is_treap: "treap l1" using "3.prems"(1) sub_treap[of l1 k1 p1 r1] by (auto)

      have prios_1: "\<forall>p' \<in> prios l1.  p' \<ge> p1" using "3.prems" by (auto simp: treap_def tree.set_map)

      have "\<forall>p''\<in>prios t2. p2 \<le> p''" using get_t2 "3.prems"(2) by (auto simp: treap_def)
        then have "\<forall>p''\<in>prios t2. p1 \<le> p''" using 4  by (auto simp: treap_def tree.set_map)
      moreover have "\<forall>p''\<in>prios treap_r. p'' \<in> prios r1 \<or> p'' \<in> prios t2" 
        using get_treap_r  get_t2 merge_treap_prios_preserve[of r1 t2] by auto
      moreover have "\<forall>p''\<in>prios r1. p1  \<le> p''" using "3.prems"(1) by (auto simp: treap_def)
      ultimately have prios_2: "\<forall>p''\<in>prios treap_r. p1 \<le> p''"  by (auto)

     
      show ?thesis 
        using treap_union[of l1 treap_r k1 p1]  l1_is_treap treap_r_is_treap keys_1 keys_2 prios_1 prios_2 4 get_treap_r
        by (auto)
    next 
      case 5: False
      obtain t1 where get_t1: "t1 =  \<langle>l1, (k1,p1), r1\<rangle> " by (auto)
      obtain treap_l where get_treap_l: "treap_l = merge \<langle>l1, (k1,p1), r1\<rangle> l2" by (auto)
      have treap_l_is_treap: "treap treap_l"
        using "3.IH" 5 "3.prems" sub_treap[of l2 k2 p2 r2] get_treap_l
        by (auto simp: treap_def tree.set_map)

      have keys_3: "\<forall>k' \<in> keys r2.  k' > k2" using "3.prems"(2) by (auto simp: treap_def tree.set_map)

      have "\<forall>k''\<in>keys treap_l. k'' \<in> keys l2 \<or> k'' \<in> keys t1" 
        using get_treap_l  get_t1 merge_treap_key_preserve[of t1 l2] by auto
      moreover have "\<forall>k''\<in>keys t1. k2 > k''" using get_t1 "3.prems" by (auto)
      moreover have "\<forall>k''\<in>keys l2. k2 > k''" using "3.prems"(2) by (auto simp: treap_def)
      ultimately have keys_4: "\<forall>k''\<in>keys treap_l. k2 > k''" by (auto)

      have r2_is_treap: "treap r2" using "3.prems"(2) sub_treap[of l2 k2 p2 r2] by (auto)

      have prios_3: "\<forall>p' \<in> prios r2.  p' \<ge> p2" using "3.prems"(2) by (auto simp: treap_def tree.set_map)

      have "\<forall>p''\<in>prios t1. p1 \<le> p''" using get_t1 "3.prems"(1) by (auto simp: treap_def)
        then have "\<forall>p''\<in>prios t1. p2 \<le> p''" using 5  by (auto simp: treap_def tree.set_map)
      moreover have "\<forall>p''\<in>prios treap_l. p'' \<in> prios l2 \<or> p'' \<in> prios t1" 
        using get_treap_l  get_t1 merge_treap_prios_preserve[of t1 l2] by auto
      moreover have "\<forall>p''\<in>prios l2. p2  \<le> p''" using "3.prems"(2) by (auto simp: treap_def)
      ultimately have prios_4: "\<forall>p''\<in>prios treap_l. p2 \<le> p''"  by (auto)

     
      show ?thesis 
        using treap_union[of treap_l r2 k2 p2]  treap_l_is_treap r2_is_treap keys_3 keys_4 prios_3 prios_4 5 get_treap_l
        by (auto)
    next
  qed
qed



fun del:: "'k::linorder \<Rightarrow>  ('k \<times>'p::linorder) tree \<Rightarrow> ('k \<times> 'p) tree" where
"del k Leaf = Leaf" |

"del k \<langle>Leaf, (k1,p1), Leaf\<rangle> = 
(if k = k1 then Leaf
else \<langle>Leaf, (k1,p1), Leaf\<rangle>)" |

"del k \<langle>l1, (k1,p1), Leaf\<rangle>  = 
(if k = k1 then del k l1
else \<langle>del k l1, (k1,p1), Leaf\<rangle>)" |

"del k \<langle>Leaf, (k1,p1), r1\<rangle>  = 
(if k = k1 then del k r1
else \<langle>Leaf, (k1,p1), del k r1\<rangle>)" |

"del k \<langle>l1, (k1,p1), r1\<rangle>  =   
(if k = k1 then
merge (del k l1) (del k r1)
else \<langle>del k l1, (k1,p1), del k r1\<rangle>)
"

lemma treap_del:
"\<lbrakk>treap t \<rbrakk> \<Longrightarrow>  k \<notin> keys (del k t)"
proof(induction t  rule: del.induct)
  case (1 k)
  then show ?case by auto
next
  case (2 k k1 p1)
  then show ?case by auto
next
  case (3 k l1_l l1_k l1_r k1 p1)
  obtain treap_l where get_treap_l: "treap_l = del k \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
  have 1: "treap  \<langle>l1_l, l1_k, l1_r\<rangle>" using "3.prems" sub_treap by auto
  then show ?case 
  proof (cases "k = k1")
    case a: True
    show ?thesis using "3.IH" 1 a by auto
  next
    case b: False
    have "k \<notin> keys treap_l" using "3.IH"(2) 1 b get_treap_l by auto
    then show ?thesis using b get_treap_l by auto
  qed
next
  case (4 k k1 p1 r1_l r1_k r1_r)
  obtain treap_r where get_treap_r: "treap_r = del k \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
  have 2: "treap  \<langle>r1_l, r1_k, r1_r\<rangle>" using "4.prems" sub_treap by auto
  then show ?case 
  proof (cases "k = k1")
    case a: True
    show ?thesis using "4.IH" 2 a by auto
  next
    case b: False
    have "k \<notin> keys treap_r" using "4.IH"(2) 2 b get_treap_r by auto
    then show ?thesis using b get_treap_r  by auto
  qed
next
  case ("5_1" k l1_l l1_k l1_r k1 p1 r1_l r1_k r1_r)
  obtain treap_l where get_treap_l: "treap_l = del k \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
  obtain treap_r where get_treap_r: "treap_r = del k \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
  have 1: "treap  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_1.prems" sub_treap by auto
  have 2: "treap  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_1.prems" sub_treap by auto
  then show ?case
  proof (cases "k = k1")
    case a: True
    have "k \<notin> keys treap_l" using "5_1.IH"(1) 1 a get_treap_l by auto
    moreover have "k \<notin> keys treap_r" using "5_1.IH"(2) 2 a get_treap_r by auto
    ultimately show ?thesis using a get_treap_r get_treap_l merge_treap_key_preserve[of treap_l treap_r] cont_then_in_keys  by auto
  next
    case b: False
    have " k \<notin> keys treap_l" using "5_1.IH"(3) 1 b get_treap_l by auto
    moreover have "k \<notin> keys treap_r" using "5_1.IH"(4) 2 b get_treap_r by auto
    ultimately  show ?thesis using b get_treap_r get_treap_l  by auto 
  qed
next
 case ("5_2" k l1_l l1_k l1_r k1 p1 r1_l r1_k r1_r)
  obtain treap_l where get_treap_l: "treap_l = del k \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
  obtain treap_r where get_treap_r: "treap_r = del k \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
  have 1: "treap  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_2.prems" sub_treap by auto
  have 2: "treap  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_2.prems" sub_treap by auto
  then show ?case
  proof (cases "k = k1")
    case a: True
    have "k \<notin> keys treap_l" using "5_2.IH"(1) 1 a get_treap_l by auto
    moreover have "k \<notin> keys treap_r" using "5_2.IH"(2) 2 a get_treap_r by auto
    ultimately show ?thesis using a get_treap_r get_treap_l merge_treap_key_preserve[of treap_l treap_r] cont_then_in_keys  by auto
  next
    case b: False
    have " k \<notin> keys treap_l" using "5_2.IH"(3) 1 b get_treap_l by auto
    moreover have "k \<notin> keys treap_r" using "5_2.IH"(4) 2 b get_treap_r by auto
    ultimately  show ?thesis using b get_treap_r get_treap_l  by auto 
  qed
qed

lemma treap_del2:
"\<lbrakk>treap t \<rbrakk> \<Longrightarrow> (keys (del k t)) =  keys t - {k}"
proof(induction t  rule: del.induct)
  case (1 k)
  then show ?case by auto
next
  case (2 k k1 p1)
  then show ?case by (auto simp: treap_def)
next
    case (3 k l1_l l1_k l1_r k1 p1)
    then show ?case by (auto simp: treap_def)
next
    case (4 k k1 p1 r1_l r1_k r1_r)
    then show ?case by (auto simp: treap_def)
next
    case ("5_1" k l1_l l1_k l1_r k1 p1 r1_l r1_k r1_r)
    obtain treap_l where get_treap_l: "treap_l = del k \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
    obtain treap_r where get_treap_r: "treap_r = del k \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
    have 1: "treap  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_1.prems" sub_treap by auto
    have 2: "treap  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_1.prems" sub_treap by auto
    then show ?case
    proof (cases "k = k1")
      case a: True
      have " keys treap_l =  keys  \<langle>l1_l, l1_k, l1_r\<rangle> - {k}" using "5_1.IH"(1) 1 a get_treap_l by auto
      moreover have  " keys treap_r =  keys  \<langle>r1_l, r1_k, r1_r\<rangle> - {k}" using "5_1.IH"(2) 2 a get_treap_r by auto
      ultimately show ?thesis using a get_treap_r get_treap_l merge_treap_key_preserve[of treap_l treap_r]  by auto
  next
    case b: False
    have " keys treap_l =  keys  \<langle>l1_l, l1_k, l1_r\<rangle> - {k}" using "5_1.IH"(3) 1 b get_treap_l by auto
    moreover have " keys treap_r =  keys  \<langle>r1_l, r1_k, r1_r\<rangle> - {k}" using "5_1.IH"(4) 2 b get_treap_r by auto
    ultimately show ?thesis using b get_treap_r get_treap_l  by auto
  qed
next
  case ("5_2" k l1_l l1_k l1_r k1 p1 r1_l r1_k r1_r)
    obtain treap_l where get_treap_l: "treap_l = del k \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
    obtain treap_r where get_treap_r: "treap_r = del k \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
    have 1: "treap  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_2.prems" sub_treap by auto
    have 2: "treap  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_2.prems" sub_treap by auto
    then show ?case
    proof (cases "k = k1")
      case a: True
      have " keys treap_l =  keys  \<langle>l1_l, l1_k, l1_r\<rangle> - {k}" using "5_2.IH"(1) 1 a get_treap_l by auto
      moreover have  " keys treap_r =  keys  \<langle>r1_l, r1_k, r1_r\<rangle> - {k}" using "5_2.IH"(2) 2 a get_treap_r by auto
      ultimately show ?thesis using a get_treap_r get_treap_l merge_treap_key_preserve[of treap_l treap_r]  by auto
  next
    case b: False
    have " keys treap_l =  keys  \<langle>l1_l, l1_k, l1_r\<rangle> - {k}" using "5_2.IH"(3) 1 b get_treap_l by auto
    moreover have " keys treap_r =  keys  \<langle>r1_l, r1_k, r1_r\<rangle> - {k}" using "5_2.IH"(4) 2 b get_treap_r by auto
    ultimately show ?thesis using b get_treap_r get_treap_l  by auto
  qed
qed

lemma treap_del3:
"\<lbrakk>treap t \<rbrakk> \<Longrightarrow>  (prios (del k t)) \<subseteq>  prios t"
proof(induction t  rule: del.induct)
  case (1 k)
  then show ?case by auto
next
  case (2 k k1 p1)
  then show ?case by (auto simp: treap_def)
next
    case (3 k l1_l l1_k l1_r k1 p1)
    then show ?case by (auto simp: treap_def)
next
    case (4 k k1 p1 r1_l r1_k r1_r)
    then show ?case by (auto simp: treap_def)
next
    case ("5_1" k l1_l l1_k l1_r k1 p1 r1_l r1_k r1_r)
    obtain treap_l where get_treap_l: "treap_l = del k \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
    obtain treap_r where get_treap_r: "treap_r = del k \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
    have 1: "treap  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_1.prems" sub_treap by auto
    have 2: "treap  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_1.prems" sub_treap by auto
    then show ?case
    proof (cases "k = k1")
      case a: True
      have " prios treap_l \<subseteq>  prios  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_1.IH"(1) 1 a get_treap_l by auto
      moreover have  " prios treap_r \<subseteq>  prios  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_1.IH"(2) 2 a get_treap_r by auto
      ultimately show ?thesis using a get_treap_r get_treap_l merge_treap_prios_preserve[of treap_l treap_r]  by auto
  next
    case b: False
    have " prios treap_l \<subseteq>  prios  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_1.IH"(3) 1 b get_treap_l by auto
    moreover have " prios treap_r \<subseteq>  prios  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_1.IH"(4) 2 b get_treap_r by auto
    ultimately show ?thesis using b get_treap_r get_treap_l  by auto
  qed
next
  case ("5_2" k l1_l l1_k l1_r k1 p1 r1_l r1_k r1_r)
    obtain treap_l where get_treap_l: "treap_l = del k \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
    obtain treap_r where get_treap_r: "treap_r = del k \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
    have 1: "treap  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_2.prems" sub_treap by auto
    have 2: "treap  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_2.prems" sub_treap by auto
    then show ?case
    proof (cases "k = k1")
      case a: True
      have " prios treap_l \<subseteq>  prios  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_2.IH"(1) 1 a get_treap_l by auto
      moreover have  " prios treap_r \<subseteq>  prios  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_2.IH"(2) 2 a get_treap_r by auto
      ultimately show ?thesis using a get_treap_r get_treap_l merge_treap_prios_preserve[of treap_l treap_r]  by auto
  next
    case b: False
    have " prios treap_l \<subseteq>  prios  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_2.IH"(3) 1 b get_treap_l by auto
    moreover have " prios treap_r \<subseteq>  prios  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_2.IH"(4) 2 b get_treap_r by auto
    ultimately show ?thesis using b get_treap_r get_treap_l  by auto
  qed
qed


lemma treap_del4:
"\<lbrakk>treap t \<rbrakk> \<Longrightarrow>  treap (del k t)"
proof(induction t  rule: del.induct)
  case (1 k)
  then show ?case by auto
next
  case (2 k k1 p1)
  then show ?case by (auto simp: treap_def)
next
  case (3 k l1_l l1_k l1_r k1 p1)
  obtain l1 where get_l1: "l1 =  \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
  obtain treap_l where get_treap_l: "treap_l = del k \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
  have 1: "treap  \<langle>l1_l, l1_k, l1_r\<rangle>" using "3.prems" sub_treap by auto
  then show ?case 
  proof (cases "k = k1")
    case a: True
    show ?thesis using "3.IH"(1) 1 a by auto
  next
    case b: False

    have "\<forall>k'\<in>keys l1. k' < k1" using  get_l1 "3.prems"  by (auto simp: treap_def)
    moreover have  "keys l1 - {k} = keys treap_l" using get_l1 get_treap_l 1 treap_del2[of l1 k] by auto
    ultimately have keys_ok: "\<forall>k'\<in>keys treap_l. k' < k1"  by auto


    have "\<forall>p'\<in>prios l1. p1 \<le> p'" using  get_l1 "3.prems"  by (auto simp: treap_def)
    moreover have  "prios  treap_l \<subseteq> prios l1" using get_l1 get_treap_l 1 treap_del3[of l1 k] by auto
    ultimately have prios_ok: "\<forall>p'\<in> prios treap_l. p' \<ge> p1"  by auto

    have "treap (treap_l)" using "3.IH"(2) 1 b get_treap_l by (auto)
    then show ?thesis using b get_treap_l treap_union[of treap_l Leaf k1 p1] keys_ok prios_ok by (auto simp: treap_def)
  qed
next
  case (4 k k1 p1 r1_l r1_k r1_r)
  obtain r1 where get_r1: "r1 =  \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
  obtain treap_r where get_treap_r: "treap_r = del k \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
  have 1: "treap  \<langle>r1_l, r1_k, r1_r\<rangle>" using "4.prems" sub_treap by auto
  then show ?case 
  proof (cases "k = k1")
    case a: True
    show ?thesis using "4.IH"(1) 1 a by auto
  next
    case b: False

    have "\<forall>k'\<in>keys r1. k1 < k'" using  get_r1 "4.prems"  by (auto simp: treap_def)
    moreover have  "keys r1 - {k} = keys treap_r" using get_r1 get_treap_r 1 treap_del2[of r1 k] by auto
    ultimately have keys_ok: "\<forall>k'\<in>keys treap_r. k1 < k'"  by auto


    have "\<forall>p'\<in>prios r1. p1 \<le> p'" using  get_r1 "4.prems"  by (auto simp: treap_def)
    moreover have  "prios  treap_r \<subseteq> prios r1" using get_r1 get_treap_r 1 treap_del3[of r1 k] by auto
    ultimately have prios_ok: "\<forall>p'\<in> prios treap_r. p1 \<le> p'"  by auto

    have "treap (treap_r)" using "4.IH"(2) 1 b get_treap_r by (auto)
    then show ?thesis using b get_treap_r treap_union[of Leaf treap_r k1 p1] keys_ok prios_ok by (auto simp: treap_def)
  qed
next
  case ("5_1" k l1_l l1_k l1_r k1 p1 r1_l r1_k r1_r)
  obtain l1 where get_l1: "l1 =  \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
  obtain treap_l where get_treap_l: "treap_l = del k \<langle>l1_l, l1_k, l1_r\<rangle>" using get_l1 by (auto)
  obtain r1 where get_r1: "r1 =  \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
  obtain treap_r where get_treap_r: "treap_r = del k \<langle>r1_l, r1_k, r1_r\<rangle>" using get_r1 by (auto)
  have 1: "treap l1" using get_l1 "5_1.prems" sub_treap by auto
  have 2: "treap r1" using get_r1 "5_1.prems" sub_treap by auto

  have  "\<forall>k'\<in>keys l1. k' < k1" using  get_l1 "5_1.prems"  by (auto simp: treap_def)
  moreover have  "keys l1 - {k} = keys treap_l" using get_l1 get_treap_l 1 treap_del2[of l1 k] by auto
  ultimately have keys_l_ok: "\<forall>k'\<in>keys treap_l. k' < k1" by auto


  have "\<forall>p'\<in>prios l1. p1 \<le> p'" using  get_l1 "5_1.prems"  by (auto simp: treap_def)
  moreover have  "prios  treap_l \<subseteq> prios l1" using get_l1 get_treap_l 1 treap_del3[of l1 k] by auto
  ultimately have prios_l_ok: "\<forall>p'\<in> prios treap_l. p1  \<le> p'"  by auto


  have "\<forall>k'\<in>keys r1. k1 < k'" using  get_r1 "5_1.prems"  by (auto simp: treap_def)
  moreover have  "keys r1 - {k} = keys treap_r" using get_r1 get_treap_r 2 treap_del2[of r1 k] by auto
  ultimately have keys_r_ok: "\<forall>k''\<in>keys treap_r. k'' > k1"  by auto


  have "\<forall>p'\<in>prios r1. p1 \<le> p'" using  get_r1 "5_1.prems"  by (auto simp: treap_def)
  moreover have  "prios  treap_r \<subseteq> prios r1" using get_r1 get_treap_r 2 treap_del3[of r1 k] by auto
  ultimately have prios_r_ok: "\<forall>p'\<in> prios treap_r. p1 \<le> p'"  by auto

  then show ?case 
  proof (cases "k = k1")
    case a: True

    have "treap (treap_l)" using "5_1.IH"(1) 1 a get_treap_l get_l1 by (auto)
    moreover have  "treap (treap_r)" using "5_1.IH"(2) 2 a get_treap_r get_r1 by (auto)
    moreover have "\<forall>k'\<in>keys treap_l. \<forall>k''\<in>keys treap_r. k'  <  k''" 
      using keys_l_ok keys_r_ok less_trans
      by (blast)
    ultimately show ?thesis 
       using merge_treap[of treap_l treap_r] using get_treap_l get_treap_r a by auto
  next
    case b: False

    have "treap (treap_l)" using "5_1.IH"(3) 1 b get_treap_l get_l1 by (auto)
    moreover have  "treap (treap_r)" using "5_1.IH"(4) 2 b get_treap_r get_r1 by (auto)
    ultimately show ?thesis 
      using b get_treap_l get_treap_r treap_union[of treap_l treap_r k1 p1] keys_l_ok prios_l_ok keys_r_ok prios_r_ok 
      by (auto simp: treap_def)
  qed
next
  case ("5_2" k l1_l l1_k l1_r k1 p1 r1_l r1_k r1_r)
  obtain l1 where get_l1: "l1 =  \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
  obtain treap_l where get_treap_l: "treap_l = del k \<langle>l1_l, l1_k, l1_r\<rangle>" using get_l1 by (auto)
  obtain r1 where get_r1: "r1 =  \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
  obtain treap_r where get_treap_r: "treap_r = del k \<langle>r1_l, r1_k, r1_r\<rangle>" using get_r1 by (auto)
  have 1: "treap l1" using get_l1 "5_2.prems" sub_treap by auto
  have 2: "treap r1" using get_r1 "5_2.prems" sub_treap by auto

  have  "\<forall>k'\<in>keys l1. k' < k1" using  get_l1 "5_2.prems"  by (auto simp: treap_def)
  moreover have  "keys l1 - {k} = keys treap_l" using get_l1 get_treap_l 1 treap_del2[of l1 k] by auto
  ultimately have keys_l_ok: "\<forall>k'\<in>keys treap_l. k' < k1" by auto


  have "\<forall>p'\<in>prios l1. p1 \<le> p'" using  get_l1 "5_2.prems"  by (auto simp: treap_def)
  moreover have  "prios  treap_l \<subseteq> prios l1" using get_l1 get_treap_l 1 treap_del3[of l1 k] by auto
  ultimately have prios_l_ok: "\<forall>p'\<in> prios treap_l. p1  \<le> p'"  by auto


  have "\<forall>k'\<in>keys r1. k1 < k'" using  get_r1 "5_2.prems"  by (auto simp: treap_def)
  moreover have  "keys r1 - {k} = keys treap_r" using get_r1 get_treap_r 2 treap_del2[of r1 k] by auto
  ultimately have keys_r_ok: "\<forall>k''\<in>keys treap_r. k'' > k1"  by auto


  have "\<forall>p'\<in>prios r1. p1 \<le> p'" using  get_r1 "5_2.prems"  by (auto simp: treap_def)
  moreover have  "prios  treap_r \<subseteq> prios r1" using get_r1 get_treap_r 2 treap_del3[of r1 k] by auto
  ultimately have prios_r_ok: "\<forall>p'\<in> prios treap_r. p1 \<le> p'"  by auto

  then show ?case 
  proof (cases "k = k1")
    case a: True

    have "treap (treap_l)" using "5_2.IH"(1) 1 a get_treap_l get_l1 by (auto)
    moreover have  "treap (treap_r)" using "5_2.IH"(2) 2 a get_treap_r get_r1 by (auto)
    moreover have "\<forall>k'\<in>keys treap_l. \<forall>k''\<in>keys treap_r. k'  <  k''" 
      using keys_l_ok keys_r_ok less_trans
      by (blast)
    ultimately show ?thesis 
       using merge_treap[of treap_l treap_r] using get_treap_l get_treap_r a by auto
  next
    case b: False

    have "treap (treap_l)" using "5_2.IH"(3) 1 b get_treap_l get_l1 by (auto)
    moreover have  "treap (treap_r)" using "5_2.IH"(4) 2 b get_treap_r get_r1 by (auto)
    ultimately show ?thesis 
      using b get_treap_l get_treap_r treap_union[of treap_l treap_r k1 p1] keys_l_ok prios_l_ok keys_r_ok prios_r_ok 
      by (auto simp: treap_def)
  qed
qed


lemma treap_del5:
"\<lbrakk>treap t; k \<notin> keys t \<rbrakk> \<Longrightarrow>  t = (del k t)"
proof(induction t  rule: del.induct)
  case (1 k)
  then show ?case by auto
next
  case (2 k k1 p1)
  then show ?case by auto
next
  case (3 k l1_l l1_k l1_r k1 p1)
  obtain t where get_t: "t =  \<langle>\<langle>l1_l, l1_k, l1_r\<rangle>, (k1,p1), Leaf \<rangle>" by auto
  obtain l1 where get_l1: "l1 =  \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
  have 1: "treap  \<langle>l1_l, l1_k, l1_r\<rangle>" using "3.prems" sub_treap by auto
  then show ?case 
  proof (cases "k = k1")
    case a: True
    then have " k \<in> keys t " using get_t  by (auto simp: treap_def)
    then show ?thesis using a "3.prems"(2) by auto
  next
    case b: False

    have "keys l1 \<subseteq> keys t" using get_t get_l1 by (auto simp: treap_def)
    then have "k \<notin> keys l1" using get_t get_l1 "3.prems" by auto
    then show ?thesis using "3.IH"(2) 1 b get_l1 by auto
  qed
next
  case (4 k k1 p1 r1_l r1_k r1_r)
  obtain t where get_t: "t =  \<langle>Leaf, (k1,p1), \<langle>r1_l, r1_k, r1_r\<rangle>\<rangle>" by auto
  obtain r1 where get_r1: "r1 = \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
  have 2: "treap  \<langle>r1_l, r1_k, r1_r\<rangle>" using "4.prems" sub_treap by auto
  then show ?case 
  proof (cases "k = k1")
    case a: True
    then have " k \<in> keys t " using get_t  by (auto simp: treap_def)
    then show ?thesis using a "4.prems"(2) by auto
  next
    case b: False

    have "keys r1 \<subseteq> keys t" using get_t get_r1 by (auto simp: treap_def)
    then have "k \<notin> keys r1" using get_t get_r1 "4.prems" by auto
    then show ?thesis using "4.IH"(2) 2 b get_r1 by auto
  qed
next
  case ("5_1" k l1_l l1_k l1_r k1 p1 r1_l r1_k r1_r)
  obtain t where get_t: "t =  \<langle>\<langle>l1_l, l1_k, l1_r\<rangle>, (k1,p1),  \<langle>r1_l, r1_k, r1_r\<rangle>\<rangle>" by auto
  obtain l1 where get_l1: "l1 =  \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
  obtain r1 where get_r1: "r1 = \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
  have 1: "treap  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_1.prems" sub_treap by auto
  have 2: "treap  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_1.prems" sub_treap by auto
  then show ?case 
  proof (cases "k = k1")
    case a: True
    then have " k \<in> keys t " using get_t  by (auto simp: treap_def)
    then show ?thesis using a "5_1.prems"(2) by auto
  next
    case b: False

    have "keys l1 \<subseteq> keys t" using get_t get_l1 by (auto simp: treap_def)
    then have "k \<notin> keys l1" using get_t get_l1 "5_1.prems" by auto
    then have l1_ok: "l1 = del k l1" using get_l1 1 "5_1.IH"(3) b by auto

    have "keys r1 \<subseteq> keys t" using get_t get_r1 by (auto simp: treap_def)
    then have "k \<notin> keys r1" using get_t get_r1 "5_1.prems" by auto
    then have r1_ok: "r1 = del k r1" using get_r1 2 "5_1.IH"(4) b by auto

    show ?thesis using b get_l1 get_r1 l1_ok r1_ok by auto
  qed
next
  case ("5_2" k l1_l l1_k l1_r k1 p1 r1_l r1_k r1_r)
 obtain t where get_t: "t =  \<langle>\<langle>l1_l, l1_k, l1_r\<rangle>, (k1,p1),  \<langle>r1_l, r1_k, r1_r\<rangle>\<rangle>" by auto
  obtain l1 where get_l1: "l1 =  \<langle>l1_l, l1_k, l1_r\<rangle>" by (auto)
  obtain r1 where get_r1: "r1 = \<langle>r1_l, r1_k, r1_r\<rangle>" by (auto)
  have 1: "treap  \<langle>l1_l, l1_k, l1_r\<rangle>" using "5_2.prems" sub_treap by auto
  have 2: "treap  \<langle>r1_l, r1_k, r1_r\<rangle>" using "5_2.prems" sub_treap by auto
  then show ?case 
  proof (cases "k = k1")
    case a: True
    then have " k \<in> keys t " using get_t  by (auto simp: treap_def)
    then show ?thesis using a "5_2.prems"(2) by auto
  next
    case b: False

    have "keys l1 \<subseteq> keys t" using get_t get_l1 by (auto simp: treap_def)
    then have "k \<notin> keys l1" using get_t get_l1 "5_2.prems" by auto
    then have l1_ok: "l1 = del k l1" using get_l1 1 "5_2.IH"(3) b by auto

    have "keys r1 \<subseteq> keys t" using get_t get_r1 by (auto simp: treap_def)
    then have "k \<notin> keys r1" using get_t get_r1 "5_2.prems" by auto
    then have r1_ok: "r1 = del k r1" using get_r1 2 "5_2.IH"(4) b by auto

    show ?thesis using b get_l1 get_r1 l1_ok r1_ok by auto
  qed
qed

end
