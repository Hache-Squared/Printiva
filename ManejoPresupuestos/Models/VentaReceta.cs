using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class VentaReceta
    {
        public int VentaRecetaId { get; set; }

        [Display(Name = "Venta")]
        public int VentaId { get; set; }

        [Display(Name = "Receta")]
        public int RecetaId { get; set; }

        public decimal Cantidad { get; set; }

        [Display(Name = "Costo unitario")]
        public decimal CostoUnitario { get; set; }

        public string RecetaNombre { get; set; } = string.Empty;
        public decimal Subtotal => Cantidad * CostoUnitario;
    }
}
