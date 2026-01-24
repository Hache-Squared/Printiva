namespace ManejoPresupuestos.Models
{
    public class Impresora
    {
        public int ImpresoraId { get; set; }
        public int UsuarioId { get; set; }
        public string Nombre { get; set; }
        public string? Modelo { get; set; }
        public string? Notas { get; set; }
        public bool EstaActivo { get; set; }
    }
}
