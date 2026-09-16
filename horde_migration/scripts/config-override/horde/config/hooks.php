<?php
/**
 * No-op hooks for the local read-only export container - shadows the real
 * config/horde/config/hooks.php, which wires into Sooma-specific
 * "profissional" tables that don't exist in the read-only export DB (only
 * needed for real authentication/onboarding, irrelevant to a read-only
 * export run under a fixed, already-known username).
 */

class Horde_Hooks
{
}
