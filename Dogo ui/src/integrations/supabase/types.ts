export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      profiles: {
        Row: {
          created_at: string
          full_name: string
          id: string
          phone: string | null
          vehicle: string | null
        }
        Insert: {
          created_at?: string
          full_name?: string
          id: string
          phone?: string | null
          vehicle?: string | null
        }
        Update: {
          created_at?: string
          full_name?: string
          id?: string
          phone?: string | null
          vehicle?: string | null
        }
        Relationships: []
      }
      rider_verifications: {
        Row: {
          created_at: string
          id: string
          license_number: string
          license_photo: string | null
          nin: string | null
          reject_reason: string | null
          reviewed_at: string | null
          status: Database["public"]["Enums"]["verification_status"]
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          license_number: string
          license_photo?: string | null
          nin?: string | null
          reject_reason?: string | null
          reviewed_at?: string | null
          status?: Database["public"]["Enums"]["verification_status"]
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          license_number?: string
          license_photo?: string | null
          nin?: string | null
          reject_reason?: string | null
          reviewed_at?: string | null
          status?: Database["public"]["Enums"]["verification_status"]
          user_id?: string
        }
        Relationships: []
      }
      trip_messages: {
        Row: {
          body: string
          created_at: string
          id: string
          sender_id: string | null
          sender_kind: string
          trip_id: string
        }
        Insert: {
          body: string
          created_at?: string
          id?: string
          sender_id?: string | null
          sender_kind?: string
          trip_id: string
        }
        Update: {
          body?: string
          created_at?: string
          id?: string
          sender_id?: string | null
          sender_kind?: string
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "trip_messages_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      trips: {
        Row: {
          assigned_to: string | null
          code: string
          created_at: string
          customer_name: string
          customer_phone: string
          distance_covered_km: number | null
          distance_km: number
          dropoff: string
          fare: number
          goods_photo_url: string | null
          id: string
          moved_at: string | null
          notes: string | null
          paid_at: string | null
          payment_status: string
          pickup: string
          refund_amount: number | null
          service: Database["public"]["Enums"]["trip_service"]
          status: Database["public"]["Enums"]["trip_status"]
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          code?: string
          created_at?: string
          customer_name: string
          customer_phone: string
          distance_covered_km?: number | null
          distance_km?: number
          dropoff: string
          fare?: number
          goods_photo_url?: string | null
          id?: string
          moved_at?: string | null
          notes?: string | null
          paid_at?: string | null
          payment_status?: string
          pickup: string
          refund_amount?: number | null
          service: Database["public"]["Enums"]["trip_service"]
          status?: Database["public"]["Enums"]["trip_status"]
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          code?: string
          created_at?: string
          customer_name?: string
          customer_phone?: string
          distance_covered_km?: number | null
          distance_km?: number
          dropoff?: string
          fare?: number
          goods_photo_url?: string | null
          id?: string
          moved_at?: string | null
          notes?: string | null
          paid_at?: string | null
          payment_status?: string
          pickup?: string
          refund_amount?: number | null
          service?: Database["public"]["Enums"]["trip_service"]
          status?: Database["public"]["Enums"]["trip_status"]
          updated_at?: string
        }
        Relationships: []
      }
      user_roles: {
        Row: {
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
      vehicles: {
        Row: {
          color: string | null
          created_at: string
          id: string
          model: string
          owner_id: string
          photo: string | null
          plate: string
          reject_reason: string | null
          reviewed_at: string | null
          service: Database["public"]["Enums"]["trip_service"]
          status: Database["public"]["Enums"]["verification_status"]
        }
        Insert: {
          color?: string | null
          created_at?: string
          id?: string
          model: string
          owner_id: string
          photo?: string | null
          plate: string
          reject_reason?: string | null
          reviewed_at?: string | null
          service: Database["public"]["Enums"]["trip_service"]
          status?: Database["public"]["Enums"]["verification_status"]
        }
        Update: {
          color?: string | null
          created_at?: string
          id?: string
          model?: string
          owner_id?: string
          photo?: string | null
          plate?: string
          reject_reason?: string | null
          reviewed_at?: string | null
          service?: Database["public"]["Enums"]["trip_service"]
          status?: Database["public"]["Enums"]["verification_status"]
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      accept_trip: { Args: { _trip: string }; Returns: undefined }
      can_see_trip: { Args: { _trip: string }; Returns: boolean }
      cancel_trip: {
        Args: { _covered_km: number; _trip: string }
        Returns: number
      }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_staff: { Args: { _user_id: string }; Returns: boolean }
      list_members: {
        Args: never
        Returns: {
          created_at: string
          full_name: string
          id: string
          phone: string
          roles: string[]
          vehicle: string
        }[]
      }
      mark_trip_paid: { Args: { _trip: string }; Returns: undefined }
      my_wallet: {
        Args: never
        Returns: {
          balance: number
          today: number
          trips_done: number
        }[]
      }
      set_member_role: {
        Args: {
          _grant: boolean
          _role: Database["public"]["Enums"]["app_role"]
          _user: string
        }
        Returns: undefined
      }
    }
    Enums: {
      app_role: "admin" | "dispatcher" | "driver"
      trip_service: "taxi" | "keke" | "bike"
      trip_status:
        | "pending"
        | "accepted"
        | "en_route"
        | "picked_up"
        | "completed"
        | "cancelled"
      verification_status: "pending" | "approved" | "rejected"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "dispatcher", "driver"],
      trip_service: ["taxi", "keke", "bike"],
      trip_status: [
        "pending",
        "accepted",
        "en_route",
        "picked_up",
        "completed",
        "cancelled",
      ],
      verification_status: ["pending", "approved", "rejected"],
    },
  },
} as const
