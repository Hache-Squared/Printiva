namespace ManejoPresupuestos.Models
{
    public class TarifaActualizarDto
    {
        public int TarifaId { get; set; }
        public decimal Monto { get; set; }
        public string Moneda { get; set; } = "MXN";

        public string? Nombre { get; set; }
        public int? Orden { get; set; }
    }
}