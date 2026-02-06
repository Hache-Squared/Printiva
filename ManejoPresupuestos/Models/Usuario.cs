namespace ManejoPresupuestos.Models
{
    public class Usuario
    {
        public int Id { get; set; }
        public string Email { get; set; } = "";
        public string EmailNormalizado { get; set; } = "";
        public string PasswordHash { get; set; } = "";

        public string? Nombre { get; set; }
        public bool EstaActivo { get; set; } = true;
        public bool EsAdmin { get; set; } = false;
    }
}