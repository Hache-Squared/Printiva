namespace ManejoPresupuestos.Models
{
    // Representa cuánto se consume de un InventarioId (ej: gramos, piezas, metros, etc.)
    public class ConsumoInventarioDto
    {
        public int InventarioId { get; set; }
        public decimal CantidadUsada { get; set; }
    }
}