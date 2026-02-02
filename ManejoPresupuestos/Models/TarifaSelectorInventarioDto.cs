namespace ManejoPresupuestos.Models
{
    public class TarifaSelectorInventarioDto
    {
        public int InventarioId { get; set; }
        public decimal? Cantidad { get; set; }
        public string? Unidad { get; set; }          // lo que se muestra en tabla
        public string Display { get; set; } = "";    // lo que se muestra en tabla
    }
}