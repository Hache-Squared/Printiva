namespace ManejoPresupuestos.Models
{
    public class TarifaSelectorImpresoraDto
    {
        public int ImpresoraId { get; set; }
        public string? Nombre { get; set; }
        public string? Modelo { get; set; }

        public string Display =>
            $"{ImpresoraId} - {Nombre} {Modelo}".Replace("  ", " ").Trim();
    }
}