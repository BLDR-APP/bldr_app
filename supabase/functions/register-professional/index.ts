// supabase/functions/register-professional/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method Not Allowed' }), {
      status: 405, headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    const { email, password, fullName, role, professionalId } = await req.json()

    if (!email || !password || !fullName || !role || !professionalId) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), {
        status: 400, headers: { 'Content-Type': 'application/json' },
      })
    }

    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // ETAPA 1: Cria o usuário na autenticação do Supabase
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true,
    })

    if (authError) { throw new Error(`Auth error: ${authError.message}`) }
    if (!authData?.user?.id) { throw new Error('User created but ID not returned.') }

    const newUserId = authData.user.id;

    // ETAPA 2: Cria a linha correspondente na tabela public.profiles
    // Preenchendo TODOS os campos obrigatórios identificados pelo seu SQL.
    const { error: publicProfileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: newUserId,        // Coluna obrigatória 'id'
        user_id: newUserId,   // Coluna obrigatória 'user_id'
        full_name: fullName,  // Preenchemos para manter a consistência
        email: email,         // Preenchemos para manter a consistência
      });

    if (publicProfileError) {
      await supabaseAdmin.auth.admin.deleteUser(newUserId)
      throw new Error(`Public profile creation error: ${publicProfileError.message}`)
    }

    // ETAPA 3: Cria o perfil profissional na tabela do BLDR Club
    const { error: professionalProfileError } = await supabaseAdmin
      .schema('bldr_club')
      .from('professional_profiles')
      .insert({ user_id: newUserId, role: role, professional_id: professionalId })

    if (professionalProfileError) {
      await supabaseAdmin.auth.admin.deleteUser(newUserId)
      throw new Error(`Professional profile creation error: ${professionalProfileError.message}`)
    }

    return new Response(JSON.stringify({ message: 'Professional registered successfully' }), {
      status: 200, headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Error in register-professional function:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { 'Content-Type': 'application/json' },
    })
  }
})