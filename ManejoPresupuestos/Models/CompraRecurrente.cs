using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class CompraRecurrente
    {
        public int CompraRecurrenteId { get; set; }

        [Display(Name = "Compra")]
        public int CompraId { get; set; }
    }
}
